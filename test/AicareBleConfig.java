package aicare.net.cn.iweightlibrary.utils;

import aicare.net.cn.aicareutils.AicareUtils;
import aicare.net.cn.iweightlibrary.entity.AlgorithmInfo;
import aicare.net.cn.iweightlibrary.entity.BM09Data;
import aicare.net.cn.iweightlibrary.entity.BM15Data;
import aicare.net.cn.iweightlibrary.entity.BodyFatData;
import aicare.net.cn.iweightlibrary.entity.BroadData;
import aicare.net.cn.iweightlibrary.entity.DecimalInfo;
import aicare.net.cn.iweightlibrary.entity.User;
import aicare.net.cn.iweightlibrary.entity.WeightData;
import aicare.net.cn.iweightlibrary.scandecoder.ScanRecord;
import android.bluetooth.BluetoothDevice;
import android.os.ParcelUuid;
import android.util.SparseArray;
import androidx.annotation.NonNull;
import cn.net.aicare.GetMoreFatData;
import cn.net.aicare.MoreFatData;
import cn.net.aicare.algorithmutil.AlgorithmUtil;
import cn.net.aicare.algorithmutil.AlgorithmUtil.AlgorithmType;
import cn.net.aicare.algorithmutil.BodyFatData;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class AicareBleConfig {
  private static final String TAG = "AicareBleConfig";
  
  private static final String JD_UUID = "0000d618-0000-1000-8000-00805f9b34fb";
  
  private static final String ALI_UUID = "0000feb3-0000-1000-8000-00805f9b34fb";
  
  private static final String BM09_UUID = "0000ffa0-0000-1000-8000-00805f9b34fb";
  
  public static final byte BM_09 = 9;
  
  public static final byte BM_15 = 15;
  
  private static final byte BM_15_FLAG = -68;
  
  private static final int SUM_START = 2;
  
  private static final int SUM_END = 7;
  
  private static final byte AICARE_FLAG = -84;
  
  public static final byte TYPE_WEI_BROAD = 0;
  
  public static final byte TYPE_WEI_TEMP_BROAD = 1;
  
  private static final byte TYPE_WEI = 2;
  
  private static final byte TYPE_WEI_TEMP = 3;
  
  private static final int AICARE_TYPE_WEI = 684;
  
  private static final int AICARE_TYPE_WEI_TEMP = 940;
  
  private static final int AICARE_TYPE_UNKNOWN = 65452;
  
  private static final int ALI_FLAG = 424;
  
  static {
    try {
      System.loadLibrary("aicare-lib");
      L.e("AicareBleConfig", "load libs!");
    } catch (Exception e) {
      L.e("AicareBleConfig", "not found libs!");
    } 
  }
  
  private static final byte[] ALI_WEI = new byte[] { 1, 1, 27 };
  
  private static final byte[] ALI_FAT = new byte[] { 1, 1, 26 };
  
  private static final byte[] ALI_AICARE_FAT = new byte[] { 1, 1, 29 };
  
  private static final int AICARE_TYPE_WEI_BROAD_OLD = 2086;
  
  private static final int AICARE_TYPE_WEI_BROAD = 172;
  
  private static final int AICARE_TYPE_WEI_TEMP_BROAD = 428;
  
  public static final byte SYNC_HISTORY = -1;
  
  public static final byte UPDATE_USER_OR_LIST = -3;
  
  public static final byte SYNC_USER_INFO = -5;
  
  public static final byte SYNC_USER_ID = -6;
  
  public static final byte SYNC_DATE = -3;
  
  public static final byte SYNC_TIME = -4;
  
  public static final byte SYNC_UNIT = 6;
  
  public static final byte GET_BLE_VERSION = -9;
  
  public static final byte SYNC_LIST_OVER = 2;
  
  public static final byte SET_DID = 29;
  
  public static final byte QUERY_DID = 30;
  
  public static final byte MOVE_BLE_NAME = -8;
  
  public static final byte SET_MODE = 37;
  
  public static final int SET_MODE_ORDINARY = 0;
  
  public static final int SET_MODE_PREGNANCY = 1;
  
  private static final byte SYNC_HISTORY_OR_LIST = -49;
  
  private static final byte SETTINGS = -52;
  
  private static final byte OPERATE_OR_STATE = -2;
  
  private static final byte WEI_CHANGE = -50;
  
  private static final byte WEI_STABLE = -54;
  
  private static final byte SYNC_HISTORY_STATUS = -2;
  
  private static final byte SYNC_USER_STATUS = -4;
  
  private static final byte DATA = -53;
  
  private static final byte FAT_DATA = -2;
  
  private static final byte ADC = -3;
  
  private static final byte USER_ID = -4;
  
  private static final byte MCU_DATE = -5;
  
  private static final byte MCU_TIME = -6;
  
  private static final byte DATA_SEND_OVER = -4;
  
  private static final byte UPDATE_USER = 1;
  
  private static final byte PREGNANCY_STATE = -2;
  
  public static final byte UNIT_KG = 0;
  
  public static final byte UNIT_LB = 1;
  
  public static final byte UNIT_ST = 2;
  
  public static final byte UNIT_JIN = 3;
  
  public static final int WEIGHT_DATA = 0;
  
  public static final int SETTINGS_STATUS = 1;
  
  public static final int BLE_VERSION = 2;
  
  public static final int USER_ID_STR = 3;
  
  public static final int MCU_DATE_STR = 4;
  
  public static final int MCU_TIME_STR = 5;
  
  public static final int ADC_STR = 6;
  
  public static final int HISTORY_DATA = 7;
  
  public static final int BODY_FAT_DATA = 8;
  
  public static final int DID_STR = 9;
  
  public static final int DECIMAL_INFO = 10;
  
  public static final int ALGORITHM_INFO = 11;
  
  private static volatile boolean isHistory = false;
  
  private static byte deviceType = 2;
  
  private static final byte START_FLAG = -82;
  
  private static final int CMD_INDEX = 3;
  
  private static final byte WEI_DATA_CHANGE = 1;
  
  private static final byte WEI_DATA_STABLE = 2;
  
  private static final byte WEI_DATA_FAT = 3;
  
  public static final byte GET_DECIMAL_INFO = 4;
  
  private static final byte NEW_HISTORY_DATA = 5;
  
  public static byte[] initCmd(byte index, User user, byte unitType) {
    String[] date, time;
    byte[] b = new byte[8];
    b[0] = -84;
    b[1] = deviceType;
    if (user != null)
      L.e("AicareBleConfig", "syncUser: " + user.toString()); 
    switch (index) {
      case -1:
        b[2] = -1;
        b[6] = -49;
        break;
      case -6:
        b[2] = -6;
        b[3] = (byte)user.getId();
        b[6] = -52;
        break;
      case -5:
        b[2] = -5;
        b[3] = (byte)user.getSex();
        b[4] = Integer.valueOf(user.getAge()).byteValue();
        b[5] = Integer.valueOf(user.getHeight()).byteValue();
        b[6] = -52;
        break;
      case -3:
        date = ParseData.getDate().split("-");
        b[2] = -3;
        b[3] = Integer.valueOf(date[0].substring(2, 4)).byteValue();
        b[4] = Integer.valueOf(date[1]).byteValue();
        b[5] = Integer.valueOf(date[2]).byteValue();
        b[6] = -52;
        break;
      case -4:
        time = ParseData.getTime().split(":");
        b[2] = -4;
        b[3] = Integer.valueOf(time[0]).byteValue();
        b[4] = Integer.valueOf(time[1]).byteValue();
        b[5] = Integer.valueOf(time[2]).byteValue();
        b[6] = -52;
        break;
      case 6:
        b[2] = -2;
        b[3] = 6;
        b[4] = unitType;
        b[6] = -52;
        break;
      case -9:
        b[2] = -9;
        b[6] = -52;
        break;
      case 2:
        b[2] = -3;
        b[3] = 2;
        b[6] = -49;
        break;
    } 
    b[7] = getByteSum(b, 2, 7);
    L.i("AicareBleConfig", "initCmd: " + ParseData.byteArr2Str(b));
    return b;
  }
  
  public static byte[] initNewCmd(byte type) {
    byte[] b = new byte[6];
    b[0] = -82;
    b[1] = 3;
    b[2] = deviceType;
    b[3] = type;
    b[4] = 1;
    b[5] = getByteSum(b, 2, b.length - 1);
    return b;
  }
  
  public static byte[] initBleNameCmd(int number, Byte[] byteASCII) {
    byte[] b = new byte[8];
    b[0] = -84;
    b[1] = -1;
    b[2] = -8;
    b[3] = (byte)number;
    b[4] = byteASCII[0].byteValue();
    b[5] = byteASCII[1].byteValue();
    b[6] = -52;
    b[7] = getByteSum(b, 2, b.length - 1);
    return b;
  }
  
  public static byte[] initDIDCmd(byte didType, int did) {
    byte[] b = new byte[8];
    b[0] = -84;
    b[1] = deviceType;
    b[2] = -2;
    b[3] = didType;
    if (didType == 29) {
      byte[] didByte = ParseData.int2byte(did);
      b[4] = didByte[0];
      b[5] = didByte[1];
    } 
    b[6] = -52;
    b[7] = getByteSum(b, 2, 7);
    return b;
  }
  
  public static byte[] initUpdateUserCmd(User user) {
    L.e("AicareBleConfig", "updateUser: " + user.toString());
    byte[] b = new byte[20];
    b[0] = -84;
    b[1] = deviceType;
    b[2] = -3;
    b[3] = 1;
    initUserListByteArray(b, 4, user);
    L.e("AicareBleConfig", "initUpdateUserCmd: " + ParseData.byteArr2Str(b));
    return b;
  }
  
  public static byte[] initPregnancy(int cmd) {
    byte[] b = new byte[8];
    b[0] = -84;
    b[1] = deviceType;
    b[2] = -2;
    b[3] = 37;
    b[4] = (byte)cmd;
    b[5] = 0;
    b[6] = -52;
    b[7] = getByteSum(b, 2, 7);
    L.e("AicareBleConfig", "initUpdateUserCmd: " + ParseData.byteArr2Str(b));
    return b;
  }
  
  private static byte getByteSum(byte[] b, int start, int end) {
    int j = 0;
    for (int i = start; i < end; i++)
      j += b[i]; 
    int result = j & 0xFF;
    return (byte)result;
  }
  
  private static boolean checkData(byte[] b) {
    if (b == null || b.length == 0)
      return false; 
    if (b.length == 8 && b[0] == -84 && (b[1] == 2 || b[1] == 3 || b[1] == 1 || b[1] == 0)) {
      byte result = getByteSum(b, 2, 7);
      return (result == b[7]);
    } 
    return false;
  }
  
  private static boolean isValid(byte[] b) {
    if (b[0] == -82 && (b[2] == 2 || b[2] == 3)) {
      if (2 + b[1] >= b.length)
        return false; 
      byte result = getByteSum(b, 2, 2 + b[1]);
      return (result == b[b.length - 1]);
    } 
    return false;
  }
  
  public static List<byte[]> initUserListCmds(List<User> userList) {
    Collections.sort(userList, new UserComparator());
    List<byte[]> bytes = (List)new ArrayList<>();
    byte[] b = new byte[0];
    for (int i = 0; i < userList.size(); i++) {
      L.e("AicareBleConfig", "userList: " + ((User)userList.get(i)).toString());
      if (i % 2 == 0) {
        b = new byte[20];
        b[0] = -84;
        b[1] = deviceType;
        b[2] = -3;
        initUserListByteArray(b, 4, userList.get(i));
        if (i == userList.size() - 1)
          bytes.add(b); 
      } else {
        initUserListByteArray(b, 12, userList.get(i));
        bytes.add(b);
      } 
    } 
    return bytes;
  }
  
  private static class UserComparator implements Comparator<User> {
    public int compare(User o1, User o2) {
      return o1.getId() - o2.getId();
    }
  }
  
  private static void initUserListByteArray(byte[] value, int baseIndex, User user) {
    value[baseIndex] = (byte)user.getId();
    value[++baseIndex] = (byte)user.getSex();
    value[++baseIndex] = (byte)user.getAge();
    value[++baseIndex] = (byte)user.getHeight();
    byte[] weightByte = ParseData.int2byte(user.getWeight());
    value[++baseIndex] = weightByte[0];
    value[++baseIndex] = weightByte[1];
    byte[] adcByte = ParseData.int2byte(user.getAdc());
    value[++baseIndex] = adcByte[0];
    value[++baseIndex] = adcByte[1];
  }
  
  public static synchronized BroadData getBroadData(BluetoothDevice device, int rssi, byte[] scanRecord) {
    ScanRecord scanResult = ScanRecord.parseFromBytes(scanRecord);
    if (scanResult != null) {
      SparseArray<byte[]> manufacturerData = scanResult.getManufacturerSpecificData();
      List<ParcelUuid> uuidList = scanResult.getServiceUuids();
      if (manufacturerData != null && manufacturerData.size() > 0) {
        int manufacturerId;
        byte[] specificData;
        BroadData broadData = new BroadData();
        broadData.setAddress(device.getAddress());
        broadData.setName(device.getName());
        broadData.setRssi(rssi);
        try {
          manufacturerId = manufacturerData.keyAt(0);
          specificData = (byte[])manufacturerData.get(manufacturerId);
        } catch (Exception e) {
          e.printStackTrace();
          return null;
        } 
        if (isListEmpty(uuidList)) {
          byte[] maId = ParseData.reverse(ParseData.int2byte(manufacturerId));
          if (maId[0] == -68) {
            broadData.setSpecificData(ParseData.contact(maId, specificData));
            broadData.setBright(true);
            broadData.setDeviceType(15);
            return broadData;
          } 
        } else if (isContainJD(uuidList)) {
          L.e("AicareBleConfig", "JD manufacturerId: " + manufacturerId);
          if (manufacturerId == 684 || manufacturerId == 940 || manufacturerId == 65452) {
            L.e("AicareBleConfig", "specificData: " + ParseData.byteArr2Str(specificData));
            setDeviceType(manufacturerId);
            broadData.setBright((getFlag(specificData) != 0));
            broadData.setDeviceType(deviceType);
            return broadData;
          } 
        } else if (isContainALI(uuidList)) {
          L.e("AicareBleConfig", "ALI manufacturerId: " + manufacturerId);
          if (manufacturerId == 424) {
            L.e("AicareBleConfig", "specificData: " + ParseData.byteArr2Str(specificData));
            if (!isArrEmpty(specificData) && (isArrStartWith(specificData, ALI_WEI) || isArrStartWith(specificData, ALI_FAT) || isArrStartWith(specificData, ALI_AICARE_FAT))) {
              setDeviceType(specificData);
              broadData.setBright((getFlag(specificData) != 0));
              broadData.setDeviceType(deviceType);
              return broadData;
            } 
          } 
        } else if (isContainAicare(uuidList)) {
          L.e("AicareBleConfig", "Aicare manufacturerId: " + manufacturerId);
          if (manufacturerId == 684 || manufacturerId == 940 || manufacturerId == 65452) {
            L.e("AicareBleConfig", "specificData: " + ParseData.byteArr2Str(specificData));
            setDeviceType(manufacturerId);
            broadData.setBright((getFlag(specificData) != 0));
            broadData.setDeviceType(deviceType);
            return broadData;
          } 
          if (manufacturerId == 172 || manufacturerId == 428) {
            setDeviceType(manufacturerId);
            broadData.setBright(true);
            broadData.setSpecificData(getSpecialData(device.getAddress(), specificData));
            broadData.setDeviceType(deviceType);
            return broadData;
          } 
        } else {
          if (manufacturerId == 2086) {
            broadData.setSpecificData(specificData);
            broadData.setBright(true);
            broadData.setDeviceType(0);
            return broadData;
          } 
          if (isBM09(uuidList)) {
            byte[] maId = ParseData.reverse(ParseData.int2byte(manufacturerId));
            broadData.setSpecificData(ParseData.contact(maId, specificData));
            broadData.setBright(true);
            broadData.setDeviceType(9);
            return broadData;
          } 
        } 
      } 
    } 
    return null;
  }
  
  private static byte[] getSpecialData(String deviceAddress, byte[] src) {
    byte[] address = ParseData.address2byte(deviceAddress);
    byte[] dest = Arrays.copyOf(address, 10);
    dest[6] = 11;
    dest[7] = -1;
    dest[8] = 38;
    dest[9] = 8;
    if (ParseData.arrStartWith(dest, src))
      return Arrays.copyOfRange(src, dest.length, src.length); 
    return null;
  }
  
  private static void setDeviceType(int manufacturerId) {
    switch (manufacturerId) {
      case 684:
        deviceType = 2;
        break;
      case 940:
        deviceType = 3;
        break;
      case 172:
        deviceType = 0;
        break;
      case 428:
        deviceType = 1;
        break;
    } 
  }
  
  private static void setDeviceType(byte[] specificData) {
    if (isArrStartWith(specificData, ALI_WEI)) {
      deviceType = 2;
    } else if (isArrStartWith(specificData, ALI_AICARE_FAT) || isArrStartWith(specificData, ALI_FAT)) {
      deviceType = 2;
    } else {
      deviceType = 2;
    } 
  }
  
  private static int getFlag(byte[] data) {
    if (data.length < 7)
      return 0; 
    return (data[6] > 1 || data[6] < 0) ? 0 : data[6];
  }
  
  private static boolean isArrStartWith(byte[] src, byte[] tar) {
    if (src.length != 0 && tar.length != 0) {
      for (int i = 0; i < tar.length; i++) {
        if (tar[i] != src[i])
          return false; 
      } 
      return true;
    } 
    return false;
  }
  
  private static boolean isContainJD(List<ParcelUuid> uuidList) {
    return (!isListEmpty(uuidList) && uuidList.contains(ParcelUuid.fromString("0000d618-0000-1000-8000-00805f9b34fb")) && uuidList.contains(ParcelUuid.fromString("0000ffb0-0000-1000-8000-00805f9b34fb")));
  }
  
  private static boolean isContainALI(List<ParcelUuid> uuidList) {
    return (!isListEmpty(uuidList) && uuidList.contains(ParcelUuid.fromString("0000feb3-0000-1000-8000-00805f9b34fb")) && uuidList.contains(ParcelUuid.fromString("0000ffb0-0000-1000-8000-00805f9b34fb")));
  }
  
  private static boolean isContainAicare(List<ParcelUuid> uuidList) {
    return (!isListEmpty(uuidList) && uuidList.contains(ParcelUuid.fromString("0000ffb0-0000-1000-8000-00805f9b34fb")));
  }
  
  private static boolean isBM09(List<ParcelUuid> uuidList) {
    return (!isListEmpty(uuidList) && uuidList.contains(ParcelUuid.fromString("0000ffa0-0000-1000-8000-00805f9b34fb")));
  }
  
  private static boolean isArrEmpty(byte[] b) {
    return (b == null || b.length == 0);
  }
  
  private static <T> boolean isListEmpty(List<T> list) {
    return (list == null || list.size() == 0);
  }
  
  public static SparseArray<Object> getDatas(String mac, byte[] b) {
    L.i(AicareBleConfig.class, "getDatas: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    if (checkData(b)) {
      switch (b[6]) {
        case -54:
        case -50:
          sparseArray = getWeiData(mac, b);
          break;
        case -53:
          sparseArray = getData(b);
          break;
        case -52:
          sparseArray = getDeviceStatus(b);
          break;
        case -49:
          if (b[2] == -2) {
            sparseArray = getHistoryStatus(b);
            break;
          } 
          if (b[2] == -4)
            sparseArray = getSyncUserStatus(b); 
          break;
      } 
    } else if (isValid(b)) {
      sparseArray = getBleData(mac, b);
    } else if (isHistoryData(b)) {
      byte[] historyBytes = getConcatBytes(b);
      sparseArray = getHistoryData(historyBytes);
    } else {
      byte[] unpack = unpack(b);
      if (unpack != null)
        if (unpack[0] == -84) {
          if (unpack[2] == -9) {
            String version = getVersion(unpack, 3, 2015);
            L.e("AicareBleConfig", "version: " + version);
            sparseArray.put(2, version);
          } else if (unpack[2] == -2 && unpack[6] == -49) {
            sparseArray = getHistoryStatus(unpack);
          } 
        } else if (unpack[0] == -82) {
          sparseArray = getDecimalInfo(unpack);
        }  
    } 
    return sparseArray;
  }
  
  private static byte[] unpack(byte[] bytes) {
    List<Integer> list = getIndex(bytes);
    if (!list.isEmpty())
      for (int i = 0; i < list.size(); i++) {
        int index = ((Integer)list.get(i)).intValue();
        if (bytes.length >= index + 8 && bytes[index] == -84) {
          if (bytes[index + 2] == -9) {
            byte[] version = new byte[8];
            System.arraycopy(bytes, index, version, 0, version.length);
            return version;
          } 
          if (bytes[index + 2] == -2 && bytes[index + 6] == -49) {
            byte[] historyStatus = new byte[8];
            System.arraycopy(bytes, index, historyStatus, 0, historyStatus.length);
            return historyStatus;
          } 
        } else if (bytes[index] == -82 && bytes[index + 3] == 4) {
          if (bytes[index + 1] == 5) {
            if (bytes.length >= index + 8) {
              byte[] decimal = new byte[8];
              System.arraycopy(bytes, index, decimal, 0, decimal.length);
              return decimal;
            } 
          } else if (bytes[index + 1] == 6 && 
            bytes.length >= index + 9) {
            byte[] decimal = new byte[9];
            System.arraycopy(bytes, index, decimal, 0, decimal.length);
            return decimal;
          } 
        } 
      }  
    return null;
  }
  
  private static List<Integer> getIndex(byte[] b) {
    List<Integer> list = new ArrayList<>();
    for (int i = 0; i < b.length; i++) {
      if (b[i] == -84 || b[i] == -82)
        list.add(Integer.valueOf(i)); 
    } 
    return list;
  }
  
  private static BodyFatData bodyFatData = null;
  
  private static SparseArray<Object> getBodyFatData(byte[] b) {
    double weight, bmi, bfr, sfr;
    int uvi;
    double rom, bmr, bm, vwc;
    int bodyAge;
    double pp;
    L.i(AicareBleConfig.class, "getBodyFatData: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    if (bodyFatData == null)
      bodyFatData = new BodyFatData(); 
    switch (b[3]) {
      case 0:
        weight = ParseData.getDataInt(4, 5, b);
        bodyFatData.setWeight(weight);
        break;
      case 1:
        bmi = ParseData.getDataInt(4, 5, b) / 10.0D;
        bodyFatData.setBmi(bmi);
        break;
      case 2:
        bfr = ParseData.getDataInt(4, 5, b) / 10.0D;
        bodyFatData.setBfr(bfr);
        break;
      case 3:
        sfr = ParseData.getDataInt(4, 5, b) / 10.0D;
        bodyFatData.setSfr(sfr);
        break;
      case 4:
        uvi = ParseData.getDataInt(4, 5, b);
        bodyFatData.setUvi(uvi);
        break;
      case 5:
        rom = ParseData.getDataInt(4, 5, b) / 10.0D;
        bodyFatData.setRom(rom);
        break;
      case 6:
        bmr = ParseData.getDataInt(4, 5, b);
        bodyFatData.setBmr(bmr);
        break;
      case 7:
        bm = ParseData.getDataInt(4, 5, b) / 10.0D;
        bodyFatData.setBm(bm);
        break;
      case 8:
        vwc = ParseData.getDataInt(4, 5, b) / 10.0D;
        bodyFatData.setVwc(vwc);
        break;
      case 9:
        bodyAge = ParseData.getDataInt(4, 5, b);
        bodyFatData.setBodyAge(bodyAge);
        break;
      case 10:
        pp = ParseData.getDataInt(4, 5, b) / 10.0D;
        bodyFatData.setPp(pp);
        break;
      case -4:
        L.e("AicareBleConfig", "DATA_SEND_OVER");
        break;
    } 
    return sparseArray;
  }
  
  private static SparseArray<Object> getData(byte[] b) {
    String date, time;
    SparseArray<Object> sparseArray = new SparseArray();
    switch (b[2]) {
      case -2:
        sparseArray = getBodyFatData(b);
        break;
      case -3:
        sparseArray = getADC(b);
        break;
      case -4:
        sparseArray = getUserId(b);
        break;
      case -5:
        date = getDateOrTime((byte)-5, b, 3);
        if (bodyFatData == null)
          bodyFatData = new BodyFatData(); 
        bodyFatData.setDate(date);
        sparseArray.put(4, date);
        break;
      case -6:
        time = getDateOrTime((byte)-6, b, 3);
        if (bodyFatData == null)
          bodyFatData = new BodyFatData(); 
        bodyFatData.setTime(time);
        sparseArray.put(5, time);
        break;
    } 
    return sparseArray;
  }
  
  private static String getDateOrTime(byte type, byte[] b, int index) {
    L.i(AicareBleConfig.class, "getDateOrTime: " + ParseData.byteArr2Str(b));
    StringBuilder sBuilder = new StringBuilder();
    String yearOrHour = String.valueOf(ParseData.binaryToDecimal(b[index]));
    String monthOrMinute = String.valueOf(ParseData.binaryToDecimal(b[++index]));
    String dayOrSecond = String.valueOf(ParseData.binaryToDecimal(b[++index]));
    switch (type) {
      case -5:
        sBuilder.append("20");
        sBuilder.append(ParseData.addZero(yearOrHour));
        sBuilder.append("-");
        sBuilder.append(ParseData.addZero(monthOrMinute));
        sBuilder.append("-");
        sBuilder.append(ParseData.addZero(dayOrSecond));
        L.i(AicareBleConfig.class, "MCU_DATE = " + sBuilder.toString());
        break;
      case -6:
        sBuilder.append(ParseData.addZero(yearOrHour));
        sBuilder.append(":");
        sBuilder.append(ParseData.addZero(monthOrMinute));
        sBuilder.append(":");
        sBuilder.append(ParseData.addZero(dayOrSecond));
        L.i(AicareBleConfig.class, "MCU_TIME = " + sBuilder.toString());
        break;
    } 
    return sBuilder.toString();
  }
  
  private static AlgorithmInfo algorithmInfo = null;
  
  private static SparseArray<Object> getADC(byte[] b) {
    int algorithmId, adc;
    L.i(AicareBleConfig.class, "getADC: " + ParseData.byteArr2Str(b));
    SparseArray<Object> map = new SparseArray();
    switch (b[3]) {
      case 0:
        map.put(1, Integer.valueOf(20));
        algorithmId = ParseData.getDataInt(4, 5, b);
        if (algorithmId > 0 && algorithmInfo == null) {
          algorithmInfo = new AlgorithmInfo();
          algorithmInfo.setAlgorithmId(algorithmId);
        } 
        break;
      case 1:
        adc = ParseData.getDataInt(4, 5, b);
        map.put(1, Integer.valueOf(26));
        if (algorithmInfo != null) {
          algorithmInfo.setAdc(adc);
          if (bodyFatData != null) {
            algorithmInfo.setWeight(bodyFatData.getWeight());
            bodyFatData = null;
          } 
          map.put(11, algorithmInfo);
          algorithmInfo = null;
          break;
        } 
        if (bodyFatData == null)
          bodyFatData = new BodyFatData(); 
        bodyFatData.setAdc(adc);
        map.put(6, Integer.valueOf(adc));
        break;
      case -1:
        map.put(1, Integer.valueOf(21));
        break;
    } 
    return map;
  }
  
  private static SparseArray<Object> getUserId(byte[] b) {
    L.i(AicareBleConfig.class, "getUserId: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    if (b[3] == Byte.MAX_VALUE) {
      sparseArray.put(1, Integer.valueOf(19));
    } else {
      sparseArray.put(3, String.valueOf(ParseData.binaryToDecimal(b[3])));
    } 
    return sparseArray;
  }
  
  private static SparseArray<Object> getWeiData(String mac, byte[] b) {
    SparseArray<Object> sparseArray = new SparseArray();
    sparseArray.put(0, getWeightData(mac, b));
    return sparseArray;
  }
  
  private static SparseArray<Object> getBleData(String mac, byte[] b) {
    SparseArray<Object> sparseArray = new SparseArray();
    switch (b[3]) {
      case 1:
        sparseArray = getWeiData(mac, b, 1);
        break;
      case 2:
        sparseArray = getWeiData(mac, b, 2);
        break;
      case 4:
        sparseArray = getDecimalInfo(b);
        break;
    } 
    return sparseArray;
  }
  
  private static SparseArray<Object> getWeiData(String mac, byte[] b, int cmdType) {
    L.i(AicareBleConfig.class, "getWeiData: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    int index = 3;
    double weight = ParseData.getData(++index, ++index, ++index, b);
    double temp = Double.MAX_VALUE;
    if (b[2] == 3)
      temp = getTemp(++index, ++index, b); 
    if (cmdType == 2) {
      if (bodyFatData == null)
        bodyFatData = new BodyFatData(); 
      bodyFatData.setWeight(weight);
    } 
    sparseArray.put(0, new WeightData(mac, cmdType, weight, temp, null));
    return sparseArray;
  }
  
  private static SparseArray<Object> getDecimalInfo(byte[] b) {
    L.i(AicareBleConfig.class, "" + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    int index = 4;
    sparseArray.put(10, getDecimalInfo(b, index));
    return sparseArray;
  }
  
  private static DecimalInfo getDecimalInfo(byte[] b, int index) {
    int sourceDecimal = b[++index] >> 4;
    int kgDecimal = b[index] & 0xF;
    int lbDecimal = b[++index] >> 4;
    int stDecimal = b[index] & 0xF;
    int kgGraduation = 0;
    int lbGraduation = 0;
    if (b[1] == 6) {
      kgGraduation = b[++index] >> 4;
      lbGraduation = b[index] & 0xF;
    } 
    return new DecimalInfo(sourceDecimal, kgDecimal, lbDecimal, stDecimal, kgGraduation, lbGraduation);
  }
  
  private static SparseArray<Object> getHistoryStatus(byte[] b) {
    L.i(AicareBleConfig.class, "getHistoryStatus: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    switch (b[3]) {
      case 0:
        sparseArray.put(1, Integer.valueOf(16));
        break;
      case 1:
        isHistory = true;
        sparseArray.put(1, Integer.valueOf(17));
        break;
      case 2:
        isHistory = false;
        sparseArray.put(1, Integer.valueOf(18));
        break;
    } 
    return sparseArray;
  }
  
  private static SparseArray<Object> getSyncUserStatus(byte[] b) {
    L.i(AicareBleConfig.class, "getSyncUserStatus: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    switch (b[3]) {
      case 0:
        sparseArray.put(1, Integer.valueOf(12));
        break;
      case 1:
        sparseArray.put(1, Integer.valueOf(15));
        break;
      case 2:
        sparseArray.put(1, Integer.valueOf(14));
        break;
      case 3:
        sparseArray.put(1, Integer.valueOf(15));
        break;
    } 
    return sparseArray;
  }
  
  private static SparseArray<Object> getDeviceStatus(byte[] b) {
    SparseArray<Object> sparseArray = new SparseArray();
    if (b[2] == -9) {
      String version = getVersion(b, 3, 2015);
      sparseArray.put(2, version);
    } else {
      switch (b[3]) {
        case 0:
          sparseArray.put(1, Integer.valueOf(0));
          break;
        case 1:
          sparseArray.put(1, Integer.valueOf(1));
          break;
        case 2:
          sparseArray.put(1, Integer.valueOf(2));
          break;
        case 3:
          sparseArray.put(1, Integer.valueOf(3));
          break;
        case 4:
          sparseArray.put(1, Integer.valueOf(4));
          break;
        case 5:
          sparseArray.put(1, Integer.valueOf(5));
          break;
        case 6:
          sparseArray = getChangeUnitStatus(b);
          break;
        case 7:
          sparseArray.put(1, Integer.valueOf(8));
          break;
        case 8:
          sparseArray.put(1, Integer.valueOf(9));
          break;
        case 9:
          sparseArray.put(1, Integer.valueOf(10));
          break;
        case 10:
          sparseArray.put(1, Integer.valueOf(11));
          break;
        case 16:
          L.e("AicareBleConfig", "DATA_SEND_END");
          if (bodyFatData != null && bodyFatData.getWeight() > 0.0D) {
            sparseArray.put(8, bodyFatData);
            bodyFatData = null;
          } 
          break;
        case 27:
          sparseArray.put(1, Integer.valueOf(22));
          break;
        case 29:
          sparseArray = getDid(b);
          break;
        case 30:
          sparseArray = getDid(b);
          break;
        case 37:
          sparseArray = getMode(b);
          break;
      } 
    } 
    return sparseArray;
  }
  
  private static SparseArray<Object> getDid(byte[] b) {
    SparseArray<Object> sparseArray = new SparseArray();
    switch (b[3]) {
      case 29:
        switch (b[4]) {
          case 0:
            sparseArray.put(1, Integer.valueOf(24));
            break;
          case 1:
            sparseArray.put(1, Integer.valueOf(23));
            break;
        } 
        break;
      case 30:
        sparseArray.put(9, Integer.valueOf(ParseData.getDataInt(4, 5, b)));
        break;
    } 
    return sparseArray;
  }
  
  private static SparseArray<Object> getMode(byte[] b) {
    L.i(AicareBleConfig.class, "getMode: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    if ((b[4] & 0xFF) == 254) {
      sparseArray.put(37, Boolean.valueOf(true));
    } else {
      sparseArray.put(37, Boolean.valueOf(false));
    } 
    return sparseArray;
  }
  
  private static String getVersion(byte[] b, int index, int startYear) {
    L.i(AicareBleConfig.class, "getVersion: " + ParseData.byteArr2Str(b));
    int year = ParseData.binaryToDecimal(b[index]) / 16 + startYear;
    int month = ParseData.binaryToDecimal(b[index]) % 16;
    int day = ParseData.binaryToDecimal(b[++index]);
    float version = ParseData.binaryToDecimal(b[++index]);
    BigDecimal bDecimal = new BigDecimal((version / 10.0F));
    version = bDecimal.setScale(1, 4).floatValue();
    return year + ParseData.addZero(String.valueOf(month)) + ParseData.addZero(String.valueOf(day)) + "_" + version;
  }
  
  private static SparseArray<Object> getChangeUnitStatus(byte[] b) {
    L.i(AicareBleConfig.class, "getChangeUnitStatus: " + ParseData.byteArr2Str(b));
    SparseArray<Object> sparseArray = new SparseArray();
    switch (b[4]) {
      case -2:
        sparseArray.put(1, Integer.valueOf(6));
        break;
      case -1:
        sparseArray.put(1, Integer.valueOf(7));
        break;
    } 
    return sparseArray;
  }
  
  private static double getTemp(int first, int second, byte[] b) {
    L.i(AicareBleConfig.class, "getTemp: " + ParseData.byteArr2Str(b));
    byte unit = Integer.valueOf(b[first] >> 4).byteValue();
    byte high = Integer.valueOf(b[first] & 0xF).byteValue();
    byte[] tempArr = { high, b[second] };
    double tempDou = ParseData.getDataInt(0, 1, tempArr) / 10.0D;
    if (unit == 15)
      return -tempDou; 
    return tempDou;
  }
  
  private static byte[] preByte = null;
  
  private static boolean isHistoryData(byte[] b) {
    if (b.length == 20 && (isHistoryStart(b) || b[0] == 1)) {
      preByte = b;
      L.i(AicareBleConfig.class, "isHistoryData:true");
      return true;
    } 
    if (preByte != null && 
      isHistoryStart(preByte) && (preByte[3] == 0 || preByte[4] == 0) && b[0] == 1) {
      preByte = null;
      L.i(AicareBleConfig.class, "isHistoryData:true");
      return true;
    } 
    preByte = null;
    L.i(AicareBleConfig.class, "isHistoryData:false");
    return false;
  }
  
  private static boolean isHistoryStart(byte[] b) {
    return ((b[0] == -84 && (b[1] == 2 || b[1] == 3) && b[2] == -1) || (b[0] == -82 && (b[2] == 2 || b[2] == 3) && b[3] == 5));
  }
  
  private static volatile byte[] mByte = null;
  
  private static synchronized byte[] getConcatBytes(byte[] b) {
    L.i("getConcatBytes:new=" + ParseData.byteArr2Str(b) + " \n old=" + ((mByte != null) ? ParseData.byteArr2Str(b) : "null"));
    if (mByte != null) {
      int index = -1;
      if (mByte[0] == -84) {
        index = 3;
      } else if (mByte[0] == -82) {
        index = 4;
      } 
      if (index == -1)
        return b; 
      if ((b[0] & 0xFF) - (mByte[index] & 0xFF) == 1) {
        byte[] result = ParseData.contact(mByte, b);
        mByte = null;
        return result;
      } 
      mByte = null;
    } else {
      mByte = b;
    } 
    return b;
  }
  
  private static SparseArray<Object> getHistoryData(byte[] b) {
    L.i(AicareBleConfig.class, "getHistoryData: " + ParseData.byteArr2Str(b) + " \n b.length = " + b.length);
    SparseArray<Object> sparseArray = new SparseArray();
    if (b.length > 20) {
      int index = -1;
      if (b[0] == -84)
        index = 6; 
      if (b[0] == -82)
        index = 5; 
      if (index == -1)
        return sparseArray; 
      String date = getDateOrTime((byte)-5, b, index);
      index += 3;
      String time = getDateOrTime((byte)-6, b, index);
      index += 3;
      double weight = -1.0D;
      if (b[0] == -84)
        weight = ParseData.getDataInt(index++, index, b); 
      if (b[0] == -82)
        weight = ParseData.getData(index++, index++, index, b); 
      if (weight == -1.0D)
        return sparseArray; 
      double bmi = ParseData.getDataInt(++index, ++index, b) / 10.0D;
      double bfr = ParseData.getPercent(ParseData.getDataInt(++index, ++index, b) / 10.0D);
      double sfr = ParseData.getDataInt(++index, ++index, b) / 10.0D;
      index++;
      int uvi = ParseData.getDataInt(++index, ++index, b);
      double rom = ParseData.getPercent(ParseData.getDataInt(++index, ++index, b) / 10.0D);
      double bmr = ParseData.getDataInt(++index, ++index, b);
      double bm = ParseData.getDataInt(++index, ++index, b) / 10.0D;
      double vwc = ParseData.getPercent(ParseData.getDataInt(++index, ++index, b) / 10.0D);
      int bodyAge = ParseData.binaryToDecimal(b[++index]);
      double pp = ParseData.getDataInt(++index, ++index, b) / 10.0D;
      int number = ParseData.binaryToDecimal(b[++index]);
      int sex = ParseData.binaryToDecimal(b[++index]);
      int age = ParseData.binaryToDecimal(b[++index]);
      int height = ParseData.binaryToDecimal(b[++index]);
      int adc = ParseData.getDataInt(++index, ++index, b);
      BodyFatData bodyFatData = new BodyFatData(date, time, weight, bmi, bfr, sfr, uvi, rom, bmr, bm, vwc, bodyAge, pp, number, sex, age, height, adc, null);
      if (isHistory) {
        sparseArray.put(7, bodyFatData);
      } else {
        L.e("");
      } 
    } else {
      L.e(""+ ParseData.byteArr2Str(b));
    } 
    return sparseArray;
  }
  
  public static byte[] getRandomBytes() {
    return AicareUtils.initRandomByteArr();
  }
  
  public static byte[] encrypt(byte[] bytes, boolean isEight) {
    return AicareUtils.encrypt(bytes, isEight);
  }
  
  public static byte[] decrypt(byte[] bytes, boolean isEight) {
    return AicareUtils.decrypt(bytes, isEight);
  }
  
  public static boolean compareBytes(byte[] b1, byte[] b2) {
    if (b1.length >= 2 && b2.length >= 2)
      return AicareUtils.compareBytes(b1, b2); 
    return false;
  }
  
  public static boolean compareVersion(String date, String version) {
    return AicareUtils.compareVersion(date, version);
  }
  
  public static boolean compareAddress(String address) {
    return AicareUtils.compareAddress(address);
  }
  
  public static WeightData getWeightData(byte[] b) {
    return getWeightData("", b);
  }
  
  public static WeightData getWeightData(String mac, byte[] b) {
    if (checkData(b) && (b[6] == -50 || b[6] == -54)) {
      double weight = ParseData.getDataInt(2, 3, b);
      double temp = Double.MAX_VALUE;
      int cmdType = 1;
      if (b[1] == 3 || b[1] == 1)
        temp = getTemp(4, 5, b); 
      if (b[6] == -50)
        cmdType = 1; 
      if (b[6] == -54) {
        cmdType = 2;
        if (bodyFatData == null)
          bodyFatData = new BodyFatData(); 
        bodyFatData.setWeight(weight);
      } 
      return new WeightData(mac, cmdType, weight, temp, null);
    } 
    return null;
  }
  
  public static String getWeight(double weight, byte unit, DecimalInfo decimalInfo) {
    if (decimalInfo == null)
      decimalInfo = new DecimalInfo(1, 1, 1, 1, 1, 1); 
    switch (unit) {
      default:
        weiStr = ParseData.getKgWeight(weight, decimalInfo);
        return weiStr;
      case 1:
        weiStr = ParseData.kg2lb(weight, decimalInfo);
        return weiStr;
      case 2:
        weiStr = ParseData.kg2st(weight, decimalInfo);
        return weiStr;
      case 3:
        break;
    } 
    String weiStr = ParseData.kg2jin(weight, decimalInfo);
    return weiStr;
  }
  
  @NonNull
  public static BM09Data getBm09Data(String address, byte[] specialData) {
    BM09Data data = new BM09Data();
    if (specialData == null || specialData.length < 18)
      return data; 
    byte[] decryptData = decrypt(Arrays.copyOfRange(specialData, 0, 16), false);
    byte[] newData = ParseData.contact(decryptData, Arrays.copyOfRange(specialData, 16, specialData.length));
    if (newData == null)
      return data; 
    data.setAddress(address);
    int agreementType = newData[0] >> 4;
    data.setAgreementType(agreementType);
    int unitType = newData[0] & 0xF;
    data.setUnitType(unitType);
    DecimalInfo decimalInfo = getDecimalInfo(newData, 0);
    data.setDecimalInfo(decimalInfo);
    float weight = ParseData.getData(3, 4, 5, newData);
    data.setWeight(weight);
    int adc = ParseData.getDataInt(6, 7, newData);
    data.setAdc(adc);
    float temp = ParseData.getDataInt(8, 9, newData) / 10.0F;
    data.setTemp(temp);
    boolean isStable = (newData[10] >> 6 == 1);
    data.setStable(isStable);
    int algorithmType = ParseData.getDataInt((byte)(newData[10] & 0x3F), newData[11]);
    data.setAlgorithmId(algorithmType);
    int did = ParseData.getDataInt(12, 13, newData);
    data.setDid(did);
    String bleVersion = getVersion(newData, 15, 2018);
    data.setBleVersion(bleVersion);
    int bleType = ParseData.binaryToDecimal(newData[14]);
    data.setBleType(bleType);
    data.setTimeMillis(System.currentTimeMillis());
    return data;
  }
  
  public static BM15Data getBm15Data(String address, byte[] specialData) {
    BM15Data data = new BM15Data();
    if (specialData != null && specialData.length > 11 && specialData[0] == -68) {
      data.setAddress(address);
      byte[] decryptData = decrypt(Arrays.copyOfRange(specialData, 3, 11), true);
      System.arraycopy(decryptData, 0, specialData, 3, decryptData.length);
      String version = ParseData.keepDecimal(ParseData.binaryToDecimal(specialData[1]) / 10.0D, 1);
      data.setVersion(version);
      int agreementType = specialData[2] >> 3 & 0xF;
      data.setAgreementType(agreementType);
      int unitType = specialData[2] & 0x7;
      data.setUnitType(unitType);
      int decimal = ((specialData[2] >> 7 & 0x1) == 1) ? 2 : 1;
      data.setDecimal(decimal);
      float weight = ParseData.getWeight(3, 4, specialData);
      data.setWeight(weight);
      int adc = ParseData.getDataInt(5, 6, specialData);
      data.setAdc(adc);
      float temp = ParseData.getTemp(7, 8, specialData);
      data.setTemp(temp);
      int algorithmType = ParseData.binaryToDecimal(specialData[9]);
      data.setAlgorithmId(algorithmType);
      int did = ParseData.binaryToDecimal(specialData[10]);
      data.setDid(did);
      int bleType = ParseData.binaryToDecimal((byte)15);
      data.setBleType(bleType);
    } 
    return data;
  }
  
  public static BodyFatData getBM15BodyFatData(WeightData weightData, int sex, int age, int height) {
    BodyFatData bodyFatData = new BodyFatData();
    bodyFatData.setDate(ParseData.getDate());
    bodyFatData.setTime(ParseData.getTime());
    bodyFatData.setWeight(weightData.getWeight());
    bodyFatData.setAdc(weightData.getAdc());
    bodyFatData.setDecimalInfo(weightData.getDecimalInfo());
    bodyFatData.setSex(sex);
    bodyFatData.setAge(age);
    bodyFatData.setHeight(height);
    bodyFatData.setNumber(0);
    if (weightData.getAdc() > 0) {
      BodyFatData data = null;
      if (weightData.getAlgorithmType() == 128) {
        data = AlgorithmUtil.getBodyFatData(1, sex, age, Double.parseDouble(ParseData.getKgWeight(weightData.getWeight(), weightData.getDecimalInfo())), height, weightData
            .getAdc());
      } else if (weightData.getAlgorithmType() == 1) {
        data = AlgorithmUtil.getBodyFatData(0, sex, age, Double.parseDouble(ParseData.getKgWeight(weightData.getWeight(), weightData.getDecimalInfo())), height, weightData
            .getAdc());
      } else {
        L.e("AicareBleConfig", "No matching algorithm ID:" + weightData.getAlgorithmType());
      } 
      if (data != null) {
        bodyFatData.setBmi(data.getBmi());
        bodyFatData.setBfr(data.getBfr());
        bodyFatData.setSfr(data.getSfr());
        bodyFatData.setUvi(data.getUvi());
        bodyFatData.setRom(data.getRom());
        bodyFatData.setBmr(data.getBmr());
        bodyFatData.setBm(data.getBm());
        bodyFatData.setVwc(data.getVwc());
        bodyFatData.setBodyAge(data.getBodyAge());
        bodyFatData.setPp(data.getPp());
      } else {
        double weightKg = Double.parseDouble(ParseData.getKgWeight(weightData.getWeight(), weightData.getDecimalInfo()));
        double bmi = Math.floor(weightKg / height * height * 10.0D) / 10.0D;
        bodyFatData.setBmi(bmi);
      } 
    } 
    return bodyFatData;
  }
  
  public static MoreFatData getMoreFatData(int sex, int height, double weight, double bfr, double rom, double pp) {
    return GetMoreFatData.getMoreFatData(sex, height, weight, bfr, rom, pp);
  }
  
  public static BodyFatData getBodyFatData(@AlgorithmType int type, int sex, int age, double weight, int height, int adc) {
    return AlgorithmUtil.getBodyFatData(type, sex, age, weight, height, adc);
  }
  
  public static BodyFatData getSportModeData(BodyFatData fatData, int sex) {
    if (fatData.getAdc() > 0) {
      float bfr, rom, vwc;
      if (sex == 0 || sex == 2) {
        bfr = (float)(fatData.getBfr() - 3.5D);
        rom = (float)(fatData.getRom() + 2.5999999046325684D);
        vwc = (float)(fatData.getVwc() + 2.0D);
      } else {
        bfr = (float)(fatData.getBfr() - 3.9000000953674316D);
        rom = (float)(fatData.getRom() + 2.799999952316284D);
        vwc = (float)(fatData.getVwc() + 2.200000047683716D);
      } 
      if (bfr < 0.0F)
        bfr = 0.0F; 
      int uvi = fatData.getUvi() - 2;
      if (uvi <= 1)
        uvi = 1; 
      fatData.setBfr(bfr);
      fatData.setRom(rom);
      fatData.setVwc(vwc);
      fatData.setUvi(uvi);
    } 
    return fatData;
  }
  
  @Retention(RetentionPolicy.SOURCE)
  public static @interface SettingStatus {
    public static final int NORMAL = 0;
    
    public static final int LOW_POWER = 1;
    
    public static final int LOW_VOLTAGE = 2;
    
    public static final int ERROR = 3;
    
    public static final int TIME_OUT = 4;
    
    public static final int UNSTABLE = 5;
    
    public static final int SET_UNIT_SUCCESS = 6;
    
    public static final int SET_UNIT_FAILED = 7;
    
    public static final int SET_TIME_SUCCESS = 8;
    
    public static final int SET_TIME_FAILED = 9;
    
    public static final int SET_USER_SUCCESS = 10;
    
    public static final int SET_USER_FAILED = 11;
    
    public static final int UPDATE_USER_LIST_SUCCESS = 12;
    
    public static final int UPDATE_USER_LIST_FAILED = 13;
    
    public static final int UPDATE_USER_SUCCESS = 14;
    
    public static final int UPDATE_USER_FAILED = 15;
    
    public static final int NO_HISTORY = 16;
    
    public static final int HISTORY_START_SEND = 17;
    
    public static final int HISTORY_SEND_OVER = 18;
    
    public static final int NO_MATCH_USER = 19;
    
    public static final int ADC_MEASURED_ING = 20;
    
    public static final int ADC_ERROR = 21;
    
    public static final int REQUEST_DISCONNECT = 22;
    
    public static final int SET_DID_SUCCESS = 23;
    
    public static final int SET_DID_FAILED = 24;
    
    public static final int DATA_SEND_END = 25;
    
    public static final int ADC_SUCCESS = 26;
    
    public static final int UNKNOWN = -1;
  }
  
  @Retention(RetentionPolicy.SOURCE)
  public static @interface MODE {}
}
