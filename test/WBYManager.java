package aicare.net.cn.iweightlibrary.wby;

import aicare.net.cn.iweightlibrary.AiFitSDK;
import aicare.net.cn.iweightlibrary.bleprofile.BleManager;
import aicare.net.cn.iweightlibrary.bleprofile.BleManagerCallbacks;
import aicare.net.cn.iweightlibrary.entity.AlgorithmInfo;
import aicare.net.cn.iweightlibrary.entity.BodyFatData;
import aicare.net.cn.iweightlibrary.entity.DecimalInfo;
import aicare.net.cn.iweightlibrary.entity.User;
import aicare.net.cn.iweightlibrary.entity.WeightData;
import aicare.net.cn.iweightlibrary.utils.AicareBleConfig;
import aicare.net.cn.iweightlibrary.utils.L;
import aicare.net.cn.iweightlibrary.utils.ParseData;
import android.annotation.SuppressLint;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.text.TextUtils;
import android.util.SparseArray;
import androidx.annotation.NonNull;
import java.lang.reflect.Method;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.UUID;

public class WBYManager implements BleManager<WBYManagerCallbacks> {
  private static final String TAG = "WBYManager";
  
  private WBYManagerCallbacks mCallbacks;
  
  private BluetoothGatt mBluetoothGatt;
  
  private Context mContext;
  
  private BluetoothDevice device;
  
  private DecimalInfo decimalInfo;
  
  private DecimalInfo defaultInfo;
  
  private User user;
  
  private static final int GET_BLE_SERVICE = 1;
  
  private static final int TIMER_OUT = 2000;
  
  public static final String AICARE_SERVICE_UUID_STR = "0000ffb0-0000-1000-8000-00805f9b34fb";
  
  private static final UUID AICARE_SERVICE_UUID = UUID.fromString("0000ffb0-0000-1000-8000-00805f9b34fb");
  
  private static final UUID AICARE_NOTIFY_CHARACTERISTIC_UUID = UUID.fromString("0000ffb2-0000-1000-8000-00805f9b34fb");
  
  private static final UUID AICARE_WRITE_CHARACTERISTIC_UUID = UUID.fromString("0000ffb1-0000-1000-8000-00805f9b34fb");
  
  private static final UUID DESCR_TWO = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
  
  private static final String ERROR_CONNECTION_STATE_CHANGE = "Error on connection state change";
  
  private static final String ERROR_DISCOVERY_SERVICE = "Error on discovering services";
  
  private static final String ERROR_WRITE_DESCRIPTOR = "Error on writing descriptor";
  
  private static final String ERROR_DID = "check sdk:";
  
  private BluetoothGattCharacteristic mAicareWCharacteristic;
  
  private BluetoothGattCharacteristic mAicareNCharacteristic;
  
  private List<byte[]> usersByte = (List)new ArrayList<>();
  
  private int index = 0;
  
  private byte[] userIdByte;
  
  private byte[] userInfoByte;
  
  private byte[] dateByte;
  
  private volatile BluetoothGatt mGattOld;
  
  public static synchronized WBYManager getWBYManager() {
    return new WBYManager();
  }
  
  public void setGattCallbacks(WBYManagerCallbacks callbacks) {
    this.mCallbacks = callbacks;
  }
  
  @SuppressLint({"MissingPermission"})
  public void connect(Context context, BluetoothDevice device) {
    L.i("WBYManager", "connect");
    closeBluetoothGatt();
    this.device = device;
    if (Build.VERSION.SDK_INT >= 23) {
      this.mBluetoothGatt = device.connectGatt(context, false, this.mGattCallback, 2);
    } else {
      this.mBluetoothGatt = device.connectGatt(context, false, this.mGattCallback);
    } 
    this.mContext = context;
    this.defaultInfo = new DecimalInfo(1, 1, 1, 1, 1, 1);
    this.decimalInfo = null;
    this.mTimeOutHandler.removeMessages(5);
    this.mTimeOutHandler.sendEmptyMessageDelayed(5, 10000L);
  }
  
  @SuppressLint({"MissingPermission"})
  public void disconnect() {
    try {
      if (this.mBluetoothGatt != null) {
        this.mBluetoothGatt.disconnect();
        this.mBluetoothGatt = null;
      } 
      if (this.mLinkedList != null)
        this.mLinkedList.clear(); 
    } catch (Exception e) {
      e.printStackTrace();
    } 
  }
  
  private final BluetoothGattCallback mGattCallback = new BluetoothGattCallback() {
      @SuppressLint({"MissingPermission"})
      public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
        if (status == 0) {
          if (newState == 2 && WBYManager.this.mGattOld != gatt) {
            L.i("WBYManager", "onConnectionStateChange: gatt = " + gatt + "  mBluetoothGatt=" + WBYManager.this.mBluetoothGatt);
            WBYManager.this.mGattOld = gatt;
            WBYManager.this.mCallbacks.onDeviceConnected();
            WBYManager.this.runOnMainThread(new Runnable() {
                  public void run() {
                    WBYManager.this.mGattOld.discoverServices();
                  }
                });
            WBYManager.this.mTimeOutHandler.removeMessages(5);
            WBYManager.this.mTimeOutHandler.sendEmptyMessageDelayed(5, 10000L);
          } else if (newState == 0) {
            gatt.close();
            WBYManager.this.mCallbacks.onDeviceDisconnected();
            if (WBYManager.this.mLinkedList != null)
              WBYManager.this.mLinkedList.clear(); 
          } 
        } else {
          L.e("WBYManager", "onConnectionStateChange error: (" + status + ")");
          if (status == 133 || status == 257) {
            WBYManager.this.refresh(gatt);
            gatt.close();
            if (WBYManager.this.mBluetoothGatt != null)
              WBYManager.this.mBluetoothGatt.close(); 
            WBYManager.this.disconnect();
          } 
          WBYManager.this.mCallbacks.onError("Error on connection state change", status);
          gatt.close();
          if (WBYManager.this.mBluetoothGatt != null)
            WBYManager.this.mBluetoothGatt.close(); 
        } 
      }
      
      public void onServicesDiscovered(BluetoothGatt gatt, int status) {
        WBYManager.this.mTimeOutHandler.removeMessages(5);
        if (status == 0) {
          L.i("WBYManager", "onServicesDiscovered Success gatt=" + gatt);
          List<BluetoothGattService> services = gatt.getServices();
          if (services.isEmpty())
            WBYManager.this.disconnect(); 
          if (services.contains(gatt.getService(WBYManager.AICARE_SERVICE_UUID))) {
            BluetoothGattService aicareService = gatt.getService(WBYManager.AICARE_SERVICE_UUID);
            WBYManager.this.mAicareWCharacteristic = aicareService.getCharacteristic(WBYManager.AICARE_WRITE_CHARACTERISTIC_UUID);
            WBYManager.this.mAicareNCharacteristic = aicareService.getCharacteristic(WBYManager.AICARE_NOTIFY_CHARACTERISTIC_UUID);
            if (WBYManager.this.hasAicareUUID()) {
              WBYManager.this.mCallbacks.onServicesDiscovered();
              WBYManager.this.enableAicareIndication();
            } 
          } 
        } else {
          L.e("WBYManager", "onServicesDiscovered error: (" + status + ")");
          WBYManager.this.mCallbacks.onError("Error on discovering services", status);
        } 
      }
      
      public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
        if (status == 0) {
          if (characteristic.getUuid().equals(WBYManager.AICARE_WRITE_CHARACTERISTIC_UUID)) {
            byte[] b = characteristic.getValue();
            L.i("WBYManager", "onCharacteristicWrite: " + ParseData.byteArr2Str(b));
            WBYManager.this.mCallbacks.getCMD("Write:" + ParseData.byteArr2Str(b));
            if (!WBYManager.this.usersByte.isEmpty()) {
              System.out.println("index = " + WBYManager.this.index);
              if (WBYManager.this.index < WBYManager.this.usersByte.size() - 1) {
                if (Arrays.equals(b, WBYManager.this.usersByte.get(WBYManager.this.index)))
                  WBYManager.this.writeValue(WBYManager.this.usersByte.get(++WBYManager.this.index)); 
              } else if (Arrays.equals(b, WBYManager.this.usersByte.get(WBYManager.this.index))) {
                WBYManager.this.sendCmd((byte)2, (byte)0);
                WBYManager.this.index = 0;
              } 
            } 
            if (Arrays.equals(b, WBYManager.this.userIdByte) && WBYManager.this.userIdByte != null) {
              L.i("");
              WBYManager.this.syncUserInfo();
              WBYManager.this.userIdByte = null;
            } 
            if (Arrays.equals(b, WBYManager.this.dateByte) && WBYManager.this.dateByte != null) {
              L.i("");
              WBYManager.this.sendCmd((byte)-4, (byte)0);
              WBYManager.this.dateByte = null;
            } 
          } 
        } else {
          L.e("WBYManager", "onCharacteristicWrite error: +  (" + status + ")");
        } 
      }
      
      public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        byte[] b = characteristic.getValue();
        WBYManager.this.mCallbacks.getCMD("Changed:" + ParseData.byteArr2Str(b));
        if (characteristic.getUuid().equals(WBYManager.AICARE_NOTIFY_CHARACTERISTIC_UUID))
          try {
            String mac = gatt.getDevice().getAddress();
            WBYManager.this.handleData(mac, b);
          } catch (Exception e) {
            e.printStackTrace();
          }  
      }
      
      public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
        if (status == 0) {
          L.i("WBYManager", "onDescriptorWrite:" + WBYManager.this.bleVersion);
          if (TextUtils.isEmpty(WBYManager.this.bleVersion))
            L.i("WBYManager", "onDescriptorWrite :"+ WBYManager.this.bleVersion); 
          WBYManager.this.getDid();
          WBYManager.this.getBleVersion();
          WBYManager.this.getDecimalInfo();
        } else {
          L.e("WBYManager", "onDescriptorWrite error: +  (" + status + ")");
          WBYManager.this.mCallbacks.onError("Error on writing descriptor", status);
        } 
      }
    };
  
  @SuppressLint({"MissingPermission"})
  private void enableAicareIndication() {
    if (this.mBluetoothGatt != null) {
      this.mBluetoothGatt.setCharacteristicNotification(this.mAicareNCharacteristic, true);
      BluetoothGattDescriptor descriptor = this.mAicareNCharacteristic.getDescriptor(DESCR_TWO);
      descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
      this.mBluetoothGatt.writeDescriptor(descriptor);
      L.i("WBYManager", "enableAicareIndication sync.......................");
    } 
  }
  
  @SuppressLint({"MissingPermission"})
  public void closeBluetoothGatt() {
    try {
      this.mContext = null;
      this.user = null;
      this.decimalInfo = null;
      cancelGetVersionTimer();
      cancelAuthTimer();
      cancelGetDecimalInfoTimer();
      if (this.mLinkedList != null)
        this.mLinkedList.clear(); 
      if (this.mBluetoothGatt != null) {
        this.mBluetoothGatt.disconnect();
        this.mBluetoothGatt.close();
        this.mBluetoothGatt = null;
        this.mAicareWCharacteristic = null;
        this.mAicareNCharacteristic = null;
      } 
    } catch (Exception e) {
      e.printStackTrace();
      L.e("WBYManager", "closeBluetoothGatt error: " + e.getMessage());
    } 
  }
  
  private boolean hasAicareUUID() {
    return (this.mAicareWCharacteristic != null);
  }
  
  private LinkedList<byte[]> mLinkedList = null;
  
  private long getLinkedListTime() {
    long time = 0L;
    if (this.mLinkedList != null)
      time = this.mLinkedList.size() * 200L; 
    return time;
  }
  
  private void writeValue(byte[] b) {
    if (hasAicareUUID() && 
      b != null) {
      if (this.mLinkedList == null)
        this.mLinkedList = (LinkedList)new LinkedList<>(); 
      this.mLinkedList.addFirst(b);
      if (this.mLinkedList.size() <= 1) {
        this.mHandler.removeMessages(1);
        this.mHandler.sendEmptyMessageDelayed(1, 100L);
      } 
    } 
  }
  
  private final int SendDataKey = 1;
  
  private final int SendDataTime = 200;
  
  private final Handler mHandler = new Handler(Looper.getMainLooper()) {
      @SuppressLint({"MissingPermission"})
      public void handleMessage(Message msg) {
        if (msg.what == 1 && 
          !WBYManager.this.mLinkedList.isEmpty()) {
          byte[] sendData = WBYManager.this.mLinkedList.pollLast();
          if (sendData != null && WBYManager.this.mAicareWCharacteristic != null && WBYManager.this.mBluetoothGatt != null) {
            WBYManager.this.mAicareWCharacteristic.setValue(sendData);
            WBYManager.this.mAicareWCharacteristic.setWriteType(1);
            boolean success = WBYManager.this.mBluetoothGatt.writeCharacteristic(WBYManager.this.mAicareWCharacteristic);
            if (success)
              L.i("WBYManager", "writeValue: bytes = " + ParseData.byteArr2Str(sendData)); 
          } 
          WBYManager.this.mHandler.sendEmptyMessageDelayed(1, 200L);
        } 
      }
    };
  
  private static final int MSG_VERSION_TIME_OUT = 0;
  
  private static final int MSG_DECIMAL_TIME_OUT = 1;
  
  private static final int MSG_AUTH_TIME_OUT = 2;
  
  private static final int MSG_GET_DID = 3;
  
  private static final int MSG_GET_DID_TIME_OUT = 4;
  
  private static final int CONNECT_TIME = 5;
  
  private static final int TIME_OUT = 10000;
  
  public void sendDIDCmd(byte didType, int did) {
    byte[] b = AicareBleConfig.initDIDCmd(didType, did);
    writeValue(b);
  }
  
  public void setBleName(String name) {
    byte[] nameByte;
    if (Build.VERSION.SDK_INT >= 19) {
      nameByte = name.getBytes(StandardCharsets.US_ASCII);
    } else {
      nameByte = name.getBytes(Charset.forName("US-ASCII"));
    } 
    List<Byte[]> list = (List)new ArrayList<>();
    int i;
    for (i = 0; i < nameByte.length; i += 2) {
      Byte[] bytes = { Byte.valueOf((byte)0), Byte.valueOf((byte)0) };
      int index = i;
      bytes[0] = Byte.valueOf(nameByte[index]);
      index = i + 1;
      if (index < nameByte.length)
        bytes[1] = Byte.valueOf(nameByte[index]); 
      list.add(bytes);
    } 
    for (i = 0; i < list.size(); i++) {
      byte[] bytes = AicareBleConfig.initBleNameCmd(i, list.get(i));
      writeValue(bytes);
    } 
  }
  
  public void sendCmd(byte index, byte unitType) {
    byte[] b = AicareBleConfig.initCmd(index, null, unitType);
    writeValue(b);
  }
  
  private final Handler mTimeOutHandler = new Handler(Looper.getMainLooper()) {
      private static final int MAX_GET_DECIMAL_TIMES = 3;
      
      private int getDecimalCount = 0;
      
      public void handleMessage(@NonNull Message msg) {
        super.handleMessage(msg);
        switch (msg.what) {
          case 5:
            L.e("WBYManager", "");
            WBYManager.this.disconnect();
            if (WBYManager.this.mCallbacks != null)
              WBYManager.this.mCallbacks.onDeviceDisconnected(); 
            break;
          case 0:
            L.e("WBYManager", "");
            WBYManager.this.getVersionFail();
            WBYManager.this.onAuthStatus(false);
            WBYManager.this.getDecimalInfoFail();
            WBYManager.this.returnDecimal();
            break;
          case 1:
            L.e("WBYManager", "= " + this.getDecimalCount);
            if (this.getDecimalCount < 3) {
              WBYManager.this.getDecimalInfo();
              this.getDecimalCount++;
              break;
            } 
            this.getDecimalCount = 0;
            WBYManager.this.getDecimalInfoFail();
            WBYManager.this.returnDecimal();
            break;
          case 2:
            L.e("WBYManager", "");
            WBYManager.this.onAuthStatus(false);
            WBYManager.this.getDecimalInfoFail();
            WBYManager.this.returnDecimal();
            break;
          case 4:
            L.e("WBYManager", "");
            removeMessages(4);
            WBYManager.this.checkDid(-1);
            break;
        } 
      }
    };
  
  private static final String VERSION_MIN_DATE = "20180118";
  
  private String bleVersion;
  
  private byte[] encryptBytes;
  
  private byte[] authBytes;
  
  public void getVersionFail() {
    if (this.mCallbacks != null)
      this.mCallbacks.getResult(0, ""); 
  }
  
  public void getDecimalInfoFail() {
    this.decimalInfo = this.defaultInfo;
  }
  
  private void returnDecimal() {
    if (this.mCallbacks != null) {
      L.i("WBYManager", "");
      this.mCallbacks.onIndicationSuccess();
      this.mCallbacks.getDecimalInfo(this.decimalInfo);
    } 
  }
  
  private void getDid() {
    sendDIDCmd((byte)30, 0);
    this.mTimeOutHandler.removeMessages(4);
    this.mTimeOutHandler.sendEmptyMessageDelayed(4, 2000L + getLinkedListTime());
  }
  
  private void getBleVersion() {
    if (TextUtils.isEmpty(this.bleVersion)) {
      byte[] b = AicareBleConfig.initCmd((byte)-9, null, (byte)0);
      writeValue(b);
      cancelGetVersionTimer();
      this.mTimeOutHandler.sendEmptyMessageDelayed(0, 2000L + getLinkedListTime());
    } else if (this.mCallbacks != null) {
      this.mCallbacks.getResult(0, this.bleVersion);
    } 
  }
  
  private void cancelGetVersionTimer() {
    if (this.mTimeOutHandler == null)
      return; 
    this.mTimeOutHandler.removeMessages(0);
  }
  
  public void syncUser(User user) {
    this.user = user;
    this.userIdByte = AicareBleConfig.initCmd((byte)-6, user, (byte)0);
    this.userInfoByte = AicareBleConfig.initCmd((byte)-5, user, (byte)0);
    syncUserId();
  }
  
  private void syncUserId() {
    L.e("WBYManager", "syncUserId");
    writeValue(this.userIdByte);
  }
  
  private void syncUserInfo() {
    L.e("WBYManager", "syncUserInfo");
    writeValue(this.userInfoByte);
  }
  
  public void syncDate() {
    L.e("WBYManager", "syncDate");
    this.dateByte = AicareBleConfig.initCmd((byte)-3, null, (byte)0);
    writeValue(this.dateByte);
  }
  
  public void syncTime() {
    L.e("WBYManager", "syncTime");
    byte[] timeByte = AicareBleConfig.initCmd((byte)-4, null, (byte)0);
    writeValue(timeByte);
  }
  
  public void syncUserList(List<User> userList) {
    this.usersByte = AicareBleConfig.initUserListCmds(userList);
    if (!this.usersByte.isEmpty())
      writeValue(this.usersByte.get(this.index)); 
  }
  
  public void updateUser(User user) {
    byte[] b = AicareBleConfig.initUpdateUserCmd(user);
    writeValue(b);
  }
  
  public void setMode(int cmd) {
    byte[] b = AicareBleConfig.initPregnancy(cmd);
    writeValue(b);
  }
  
  public void getDecimalInfo() {
    L.i("WBYManager", "");
    cancelGetDecimalInfoTimer();
    this.mTimeOutHandler.sendEmptyMessageDelayed(1, 2000L + getLinkedListTime());
    byte[] b = AicareBleConfig.initNewCmd((byte)4);
    writeValue(b);
  }
  
  private void cancelGetDecimalInfoTimer() {
    if (this.mTimeOutHandler == null)
      return; 
    this.mTimeOutHandler.removeMessages(1);
  }
  
  private void handleData(String mac, byte[] b) {
    if (b[0] == -83 && b[1] == 1) {
      boolean isAuth = AicareBleConfig.compareBytes(b, this.encryptBytes);
      cancelAuthTimer();
      if (TextUtils.isEmpty(this.bleVersion) || (!TextUtils.isEmpty(this.bleVersion) && "20180118".compareTo(this.bleVersion.split("_")[0]) > 0)) {
        this.decimalInfo = this.defaultInfo;
        L.i("WBYManager", "handleData :"+ this.bleVersion);
        returnDecimal();
      } else {
        L.i("WBYManager", "handleData :"+ this.bleVersion);
        getDecimalInfo();
      } 
      onAuthStatus(isAuth);
      this.mCallbacks.getAuthData(this.authBytes, b, this.encryptBytes, isAuth);
      this.authBytes = null;
      this.encryptBytes = null;
    } 
    SparseArray<Object> sparseArray = AicareBleConfig.getDatas(mac, b);
    if (sparseArray != null && sparseArray.size() != 0)
      if (sparseArray.indexOfKey(0) >= 0) {
        if (this.decimalInfo != null) {
          WeightData weightData = (WeightData)sparseArray.get(0);
          weightData.setDecimalInfo(this.decimalInfo);
          this.mCallbacks.getWeightData(weightData);
        } 
      } else if (sparseArray.indexOfKey(1) >= 0) {
        int status = ((Integer)sparseArray.get(1)).intValue();
        this.mCallbacks.getSettingStatus(status);
        if (status == 22) {
          disconnect();
        } else if (status == 26) {
          if (sparseArray.indexOfKey(6) >= 0) {
            this.mCallbacks.getResult(4, String.valueOf(sparseArray.get(6)));
          } else if (sparseArray.indexOfKey(11) >= 0 && 
            this.decimalInfo != null) {
            AlgorithmInfo algorithmInfo = (AlgorithmInfo)sparseArray.get(11);
            algorithmInfo.setDecimalInfo(this.decimalInfo);
            this.mCallbacks.getAlgorithmInfo(algorithmInfo);
          } 
        } 
      } else if (sparseArray.indexOfKey(2) >= 0) {
        cancelGetVersionTimer();
        this.bleVersion = String.valueOf(sparseArray.get(2));
        if (AicareBleConfig.compareAddress(this.device.getAddress()) && AicareBleConfig.compareVersion(this.bleVersion.split("_")[0], this.bleVersion.split("_")[1])) {
          onAuthStatus(true);
          this.decimalInfo = this.defaultInfo;
          returnDecimal();
        } else {
          auth();
        } 
        this.mCallbacks.getResult(0, this.bleVersion);
      } else if (sparseArray.indexOfKey(3) >= 0) {
        this.mCallbacks.getResult(3, String.valueOf(sparseArray.get(3)));
      } else if (sparseArray.indexOfKey(4) >= 0) {
        this.mCallbacks.getResult(1, String.valueOf(sparseArray.get(4)));
      } else if (sparseArray.indexOfKey(5) >= 0) {
        this.mCallbacks.getResult(2, String.valueOf(sparseArray.get(5)));
      } else if (sparseArray.indexOfKey(6) >= 0) {
        this.mCallbacks.getResult(4, String.valueOf(sparseArray.get(6)));
      } else if (sparseArray.indexOfKey(7) >= 0) {
        if (this.decimalInfo != null) {
          BodyFatData historyData = (BodyFatData)sparseArray.get(7);
          historyData.setDecimalInfo(this.decimalInfo);
          this.mCallbacks.getFatData(true, historyData);
        } 
      } else if (sparseArray.indexOfKey(8) >= 0) {
        if (this.decimalInfo != null) {
          BodyFatData bodyFayData = (BodyFatData)sparseArray.get(8);
          bodyFayData.setDecimalInfo(this.decimalInfo);
          if (this.user != null) {
            bodyFayData.setNumber(this.user.getId());
            bodyFayData.setHeight(this.user.getHeight());
            bodyFayData.setSex(this.user.getSex());
            bodyFayData.setAge(this.user.getAge());
          } 
          this.mCallbacks.getFatData(false, bodyFayData);
        } 
      } else if (sparseArray.indexOfKey(9) >= 0) {
        Integer did = (Integer)sparseArray.get(9);
        checkDid(did.intValue());
      } else if (sparseArray.indexOfKey(10) >= 0) {
        cancelGetDecimalInfoTimer();
        this.decimalInfo = (DecimalInfo)sparseArray.get(10);
        returnDecimal();
      } else if (sparseArray.indexOfKey(11) >= 0) {
        if (this.decimalInfo != null) {
          AlgorithmInfo algorithmInfo = (AlgorithmInfo)sparseArray.get(11);
          algorithmInfo.setDecimalInfo(this.decimalInfo);
          this.mCallbacks.getAlgorithmInfo(algorithmInfo);
        } 
      } else if (sparseArray.indexOfKey(37) >= 0) {
        boolean status = ((Boolean)sparseArray.get(37)).booleanValue();
        this.mCallbacks.getMode(status);
      }  
  }
  
  protected void checkDid(int did) {
    this.mTimeOutHandler.removeMessages(4);
    if (did < 0) {
      boolean connectOk = AiFitSDK.getInstance().checkDid(did);
      if (!connectOk && 
        this.mCallbacks != null)
        this.mCallbacks.onError("check sdk:" + did, 0); 
    } 
    if (this.mCallbacks != null)
      this.mCallbacks.getDID(did); 
  }
  
  private void onAuthStatus(boolean isAuth) {}
  
  private void startAuthTimer() {
    cancelAuthTimer();
    this.mTimeOutHandler.sendEmptyMessageDelayed(2, 2000L + getLinkedListTime());
  }
  
  private void cancelAuthTimer() {
    this.mTimeOutHandler.removeMessages(2);
  }
  
  public void auth() {
    this.authBytes = AicareBleConfig.getRandomBytes();
    this.encryptBytes = AicareBleConfig.encrypt(Arrays.copyOfRange(this.authBytes, 2, this.authBytes.length), false);
    writeValue(this.authBytes);
    startAuthTimer();
  }
  
  private void refresh(BluetoothGatt gatt) {
    try {
      L.e("WBYManager", "refresh device cache");
      Method localMethod = gatt.getClass().getMethod("refresh", (Class[])null);
      if (localMethod != null) {
        boolean result = ((Boolean)localMethod.invoke(gatt, (Object[])null)).booleanValue();
        if (!result)
          L.e("WBYManager", "refresh failed"); 
      } 
    } catch (Exception e) {
      L.e("WBYManager", "An exception occurred while refreshing device cache");
    } 
  }
  
  private final Handler mThreadHandler = new Handler(Looper.getMainLooper());
  
  private void runOnMainThread(Runnable runnable) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      runnable.run();
    } else {
      this.mThreadHandler.post(runnable);
    } 
  }
}
