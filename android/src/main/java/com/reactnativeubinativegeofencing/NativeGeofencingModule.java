package com.reactnativecustomnativegeofencing;

import android.annotation.SuppressLint;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.location.Location;
import android.os.Build;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.module.annotations.ReactModule;
import com.reactnativecustomnativegeofencing.GeofenceBroadcastReceiver;
import com.reactnativecustomnativegeofencing.Notifications;
import com.google.android.gms.location.Geofence;
import com.google.android.gms.location.GeofencingClient;
import com.google.android.gms.location.GeofencingRequest;
import com.google.android.gms.location.LocationServices;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.reflect.TypeToken;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Headers;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

@ReactModule(name = NativeGeofencingModule.NAME)
public class NativeGeofencingModule extends ReactContextBaseJavaModule {
  public static final String NAME = "NativeGeofencing";
  private static ReactApplicationContext reactContext;
  private static GeofencingClient geofencingClient;
  private static GeofencingRequest.Builder geoBuilder;
  private static PendingIntent geofencePendingIntent;
  public static String GeofencingPrefs = "geofencing_preferences";

  public NativeGeofencingModule(ReactApplicationContext context) {
    super(context);
    reactContext = context;
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  @ReactMethod
  public void startMonitoring(ReadableMap channelOptionsMap, Promise promise) {

    try {
      if (geofencingClient == null) {
        geofencingClient = LocationServices.getGeofencingClient(reactContext.getApplicationContext());
      }

      JSONObject channelOptions = ReactNativeJson.convertMapToJson(channelOptionsMap);
      JSONObject map = new JSONObject();

      map.put("channelId", channelOptions.getString("channelId"));
      map.put("channelName", channelOptions.getString("channelName"));
      map.put("channelDescription", channelOptions.getString("channelDescription"));

      if (channelOptions.has("watchSelfLocation") && channelOptions.has("poiURL") && channelOptions.has("dataStructure")) {
        map.put("watchSelfLocation", channelOptions.get("watchSelfLocation"));
        map.put("poiURL", channelOptions.get("poiURL"));
        map.put("dataStructure", channelOptions.get("dataStructure"));

        if (channelOptions.has("fetchRadius")) {
          map.put("fetchRadius", channelOptions.getString("fetchRadius"));
        }
      }

      if (channelOptions.has("stopNotification")) {
        if (channelOptions.getJSONObject("stopNotification").has("title") && !channelOptions.getJSONObject("stopNotification").isNull("title")) {
          map.put("stopNotTitle", channelOptions.getJSONObject("stopNotification").get("title"));
        }
        if (channelOptions.getJSONObject("stopNotification").has("description") && !channelOptions.getJSONObject("stopNotification").isNull("description")) {
          map.put("stopNotMessage", channelOptions.getJSONObject("stopNotification").get("description"));
        }
      }

      saveEntries(map, "channelOptions", reactContext.getApplicationContext());

      createNotificationChannel(
        channelOptions.getString("channelId"),
        channelOptions.getString("channelName"),
        channelOptions.getString("channelDescription")
      );

      if (channelOptions.has("startNotification")) {
        String notLink = null;
        String notTitle = channelOptions.getJSONObject("startNotification").getString("title");
        String notDesc = channelOptions.getJSONObject("startNotification").getString("description");
        String channelId = channelOptions.getString("channelId");

        if (channelOptions.getJSONObject("startNotification").has("deepLink") && !channelOptions.getJSONObject("startNotification").isNull("deepLink")) {
          notLink = channelOptions.getJSONObject("startNotification").getString("deepLink");
        }

        new Notifications(reactContext.getApplicationContext(), channelId, null, notTitle, notDesc, null, notLink, null).execute();
      }

      //if watch self location start POI setup from current location
      if (map.has("watchSelfLocation")) {
        if (map.getBoolean("watchSelfLocation")) {
          SingleShotLocationProvider.requestSingleUpdate(reactContext.getApplicationContext(),
            new SingleShotLocationProvider.LocationCallback() {
              @Override
              public void onNewLocationAvailable(Location location) throws JSONException {
                Log.d("DEBUG", location.toString());
                configPoiFromMe(promise, reactContext.getApplicationContext(), location);
              }
            });

        }
      } else {
        promise.resolve("Started Geofencing Receiver, waiting for POI");
      }
    } catch (Exception e) {
      promise.reject(e.getMessage());
      e.printStackTrace();
    }
  }

  @ReactMethod
  public void stopMonitoring(Promise promise) {
    if (geofencingClient == null) {
      geofencingClient = LocationServices.getGeofencingClient(reactContext.getApplicationContext());
    }
    try {
      geofencingClient.removeGeofences(getGeofencePendingIntent(reactContext.getApplicationContext()))
        .addOnSuccessListener(
          new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void aVoid) {
              Log.d("GEOFENCE_MODULE", "Geofences stopped");
              promise.resolve("Stopped Geofencing Receiver");
            }
          })
        .addOnFailureListener(
          new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
              e.printStackTrace();
              promise.reject(e.getMessage());
            }
          }
        );
    } catch (Exception e) {
      promise.reject(e.getMessage());
      e.printStackTrace();
    }
  }


  @ReactMethod
  public void addPoi(ReadableArray entries, Promise promise) throws JSONException {
    addPois(entries, promise, reactContext.getApplicationContext());
  }

  @ReactMethod
  public void removeGeofences() {
    if (geofencingClient == null) {
      geofencingClient = LocationServices.getGeofencingClient(reactContext.getApplicationContext());
    }
    try {
      geofencingClient.removeGeofences(getGeofencePendingIntent(reactContext.getApplicationContext()))
        .addOnSuccessListener(reactContext.getCurrentActivity(), aVoid -> {
          Log.d("GEOFENCE_MODULE", "Geofences removed");
        })
        .addOnFailureListener(reactContext.getCurrentActivity(), e -> {
          e.printStackTrace();
        });
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  @SuppressLint("MissingPermission")
  private static void addPois(ReadableArray entries, Promise promise, Context context) throws JSONException {
    JSONArray entriesArray = ReactNativeJson.convertArrayToJson(entries);
    if (geofencingClient == null) {
      geofencingClient = LocationServices.getGeofencingClient(context);
    }


    try {
      saveEntriesArray(entriesArray, "geofenceEntries", context);

      geofencingClient.removeGeofences(getGeofencePendingIntent(context))
        .addOnSuccessListener(
          new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void aVoid) {

              Log.d("GEOFENCE_MODULE", "Geofences removed");
              Log.d("GEOFENCE_ENTRIES", entriesArray.toString());

              geofencingClient.addGeofences(getGeofencingRequest(entries.toArrayList()), getGeofencePendingIntent(context))
                .addOnSuccessListener(
                  new OnSuccessListener<Void>() {
                    @Override
                    public void onSuccess(Void aVoid) {
                      promise.resolve("Geofences added");
                    }
                  })
                .addOnFailureListener(
                  new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                      e.printStackTrace();
                      promise.reject("Failed to add geofences");
                    }
                  }
                );
            }
          })
        .addOnFailureListener(
          new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
              Log.d("GEOFENCE_ENTRIES", entriesArray.toString());

              geofencingClient.addGeofences(getGeofencingRequest(entries.toArrayList()), getGeofencePendingIntent(context))
                .addOnSuccessListener(
                  new OnSuccessListener<Void>() {
                    @Override
                    public void onSuccess(Void aVoid) {
                      promise.resolve("Geofences added");
                    }
                  })
                .addOnFailureListener(
                  new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                      e.printStackTrace();
                      promise.reject("Failed to add geofences");
                    }
                  }
                );
            }
          }
        );


    } catch (Exception e) {
      geofencingClient.addGeofences(getGeofencingRequest(entries.toArrayList()), getGeofencePendingIntent(context))
        .addOnSuccessListener(
          new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void aVoid) {
              promise.resolve("Geofences added");
            }
          })
        .addOnFailureListener(
          new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
              e.printStackTrace();
              promise.reject("Failed to add geofences");
            }
          }
        );

      e.printStackTrace();
    }
  }

  private static GeofencingRequest getGeofencingRequest(List entries) {
    List geofenceList = new ArrayList();

    for (int i = 0; i < entries.size(); i++) {
      Gson gson = new Gson();
      Properties entry = gson.fromJson(new Gson().toJson(entries.get(i)), Properties.class);

      geofenceList.add(new Geofence.Builder()
        // Set the request ID of the geofence. This is a string to identify this
        // geofence.
        .setRequestId(entry.getProperty("key"))
        .setExpirationDuration(Geofence.NEVER_EXPIRE)
        .setCircularRegion(
          Double.parseDouble(entry.getProperty("latitude")),
          Double.parseDouble(entry.getProperty("longitude")),
          Float.parseFloat(entry.getProperty("radius"))
        )
        .setNotificationResponsiveness(0)
        .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER |
          Geofence.GEOFENCE_TRANSITION_EXIT)
        .build());
    }

    geoBuilder = new GeofencingRequest.Builder();
    geoBuilder.setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER);
    geoBuilder.addGeofences(geofenceList);
    return geoBuilder.build();
  }

  public static void configPoiFromMe(Promise promise, Context context, Location location) throws JSONException {
    JSONObject entry = readEntries(context, "channelOptions");
    Gson gson = new Gson();
    Log.d("DEBUG LOG DATA", "START GEOFENCING READ");
    Log.d("DEBUG LOG JSON", entry.toString());

    try {
      Log.d("DEBUG MODULE", "" + location.getLatitude() + ", " + location.getLongitude());

      String poiURL = entry.getString("poiURL");
      //construct request URL based on saved channel options
      if (entry.has("fetchRadius") && entry.get("fetchRadius") != null) {
        poiURL = poiURL.replaceAll(":radius", entry.getString("fetchRadius"));
      }

      if (poiURL.contains(":latitude")) {
        poiURL = poiURL.replaceAll(":latitude", "" + location.getLatitude());
      }

      if (poiURL.contains(":longitude")) {
        poiURL = poiURL.replaceAll(":longitude", "" + location.getLongitude());
      }

      Log.d("DEBUG LOG DATA", poiURL);

      OkHttpClient client = new OkHttpClient();
      Request request = new Request.Builder()
        .url(poiURL)
        .build();

      client.newCall(request).enqueue(new Callback() {
        @Override
        public void onFailure(Call call, IOException e) {
          try {
            WritableArray list = new WritableNativeArray();
            JSONObject myPosition = new JSONObject();
            myPosition.put("key", "myCurrentLocation");
            myPosition.put("latitude", location.getLatitude());
            myPosition.put("longitude", location.getLongitude());
            myPosition.put("radius", 100);

            list.pushMap(ReactNativeJson.convertJsonToMap(myPosition));

            addPois(list, promise, context);
          } catch (JSONException ex) {
            ex.printStackTrace();
          }
        }

        @Override
        public void onResponse(Call call, Response response) throws IOException {
          try (ResponseBody responseBody = response.body()) {
            if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

            Headers responseHeaders = response.headers();
            for (int i = 0, size = responseHeaders.size(); i < size; i++) {
              System.out.println(responseHeaders.name(i) + ": " + responseHeaders.value(i));
            }

            JSONObject data = new JSONObject(responseBody.string());
            Log.d("DEBUG LOG DATA", data.toString());

            JSONArray dataStructure = entry.getJSONArray("dataStructure");
            WritableArray entries = new WritableNativeArray();

            int countNotId = 0;

            for (int dataStructureI = 0; dataStructureI < dataStructure.length(); dataStructureI++) {

              JSONObject structure = dataStructure.getJSONObject(dataStructureI);
              JSONArray poiItems = new JSONArray();

              if (structure.has("poi") && structure.get("poi") != null) {
                if (structure.has("main") && structure.get("main") != null) {
                  JSONArray structureList = structure.getJSONArray("main");

                  for (int structureListI = 0; structureListI < structureList.length(); structureListI++) {
                    try {
                      String mainPath = structureList.getString(structureListI);

                      JSONArray poiItemsCopy = new JSONArray();

                      if (poiItems.length() > 0) {
                        for (int i = 0; i < poiItems.length(); i++) {
                          JSONObject poiItem = poiItems.getJSONObject(i);
                          boolean isArray = poiItem.get(mainPath) instanceof JSONArray;

                          if (isArray) {
                            for (int poiMapI = 0; poiMapI < poiItem.getJSONArray(mainPath).length(); poiMapI++) {
                              poiItemsCopy.put(poiItem.getJSONArray(mainPath).get(poiMapI));
                            }
                          } else {
                            poiItemsCopy.put(poiItem.getJSONObject(mainPath));
                          }
                        }

                        poiItems = poiItemsCopy;
                      } else {
                        boolean isArray = data.get(mainPath) instanceof JSONArray;

                        if (isArray) {
                          for (int poiMapI = 0; poiMapI < data.getJSONArray(mainPath).length(); poiMapI++) {
                            poiItemsCopy.put(data.getJSONArray(mainPath).get(poiMapI));
                          }
                        } else {
                          poiItemsCopy.put(data.getJSONObject(mainPath));
                        }

                        poiItems = poiItemsCopy;
                      }
                    } catch (Exception e) {
                      e.printStackTrace();
                    }
                  }

                  for (int i = 0; i < poiItems.length(); i++) {
                    JSONObject poiItem = poiItems.getJSONObject(i);
                    JSONObject map = new JSONObject();

                    map.put("notificationId", String.valueOf(countNotId));
                    map.put("key", "POI_/" + countNotId);
                    JSONObject poiStructure = structure.getJSONObject("poi");

                    if (poiStructure.has("poiId") && poiStructure.get("poiId") != null) {
                      map.put("poiId", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("poiId")));
                    }

                    if (poiStructure.has("latitude") && poiStructure.get("latitude") != null) {
                      map.put("latitude", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("latitude")));
                    }

                    if (poiStructure.has("longitude") && poiStructure.get("longitude") != null) {
                      map.put("longitude", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("longitude")));
                    }

                    if (poiStructure.has("radius") && poiStructure.get("radius") != null) {
                      map.put("radius", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("radius")));
                    }

                    if (poiStructure.has("largeIcon") && poiStructure.get("largeIcon") != null) {
                      map.put("largeIcon", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("largeIcon")));
                    }

                    if (poiStructure.has("deepLink") && poiStructure.get("deepLink") != null) {
                      map.put("deepLink", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("deepLink")));
                    }

                    if (poiStructure.has("enterTitle") && poiStructure.get("enterTitle") != null) {
                      map.put("enterTitle", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("enterTitle")));
                    }

                    if (poiStructure.has("enterMessage") && poiStructure.get("enterMessage") != null) {
                      map.put("enterMessage", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("enterMessage")));
                    }

                    if (poiStructure.has("exitTitle") && poiStructure.get("exitTitle") != null) {
                      Boolean isFilteredField = isFilteredValue(poiItem, poiStructure.getJSONObject("exitTitle"));
                      if (isFilteredField) {
                        map.put("exitTitle", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("exitTitle")));
                      }
                    }

                    if (poiStructure.has("exitMessage") && poiStructure.get("exitMessage") != null) {
                      Boolean isFilteredField = isFilteredValue(poiItem, poiStructure.getJSONObject("exitMessage"));
                      if (isFilteredField) {
                        map.put("exitMessage", getValueFromStructureWithData(poiItem, poiStructure.getJSONObject("exitMessage")));
                      }
                    }

                    entries.pushMap(ReactNativeJson.convertJsonToMap(map));
                    countNotId += 1;
                  }
                }
              }

            }

            Log.d("DEBUG LOG FINAL", entries.toString());

            WritableArray list = new WritableNativeArray();


            int len = entries.size();
            if (entries != null) {
              for (int i = 0; i < len; i++) {
                //Excluding the item at position
                if (i < 20) {
                  list.pushMap(ReactNativeJson.convertJsonToMap(ReactNativeJson.convertMapToJson(entries.getMap(i))));
                } else {
                  break;
                }
              }
            }

            JSONObject myPosition = new JSONObject();
            myPosition.put("key", "myCurrentLocation");
            myPosition.put("latitude", location.getLatitude());
            myPosition.put("longitude", location.getLongitude());
            myPosition.put("radius", 100);

            list.pushMap(ReactNativeJson.convertJsonToMap(myPosition));

            addPois(list, promise, context);
          } catch (Exception e) {
            try {
              WritableArray list = new WritableNativeArray();
              JSONObject myPosition = new JSONObject();
              myPosition.put("key", "myCurrentLocation");
              myPosition.put("latitude", location.getLatitude());
              myPosition.put("longitude", location.getLongitude());
              myPosition.put("radius", 100);

              list.pushMap(ReactNativeJson.convertJsonToMap(myPosition));

              addPois(list, promise, context);
            } catch (JSONException ex) {
              ex.printStackTrace();
            }
            e.printStackTrace();
          }
        }
      });


    } catch (Exception e) {
      try {
        WritableArray list = new WritableNativeArray();
        JSONObject myPosition = new JSONObject();
        myPosition.put("key", "myCurrentLocation");
        myPosition.put("latitude", location.getLatitude());
        myPosition.put("longitude", location.getLongitude());
        myPosition.put("radius", 100);

        list.pushMap(ReactNativeJson.convertJsonToMap(myPosition));

        addPois(list, promise, context);
      } catch (JSONException ex) {
        ex.printStackTrace();
      }
      promise.reject(e.getMessage());
      e.printStackTrace();
    }

  }

  private static String getValueFromStructureWithData(JSONObject structure, JSONObject data) throws JSONException {
    try {
      String returnValue = "";

      if (data.has("type") && data.get("type") != null) {

        if (data.get("type").equals("path")) {
          if (data.has("data") && data.get("data") != null) {
            JSONArray dataStructure = data.getJSONArray("data");
            returnValue = iterateCollection(structure, dataStructure);
          }
        }

        if (data.get("type").equals("number") || data.get("type").equals("string")) {
          if (data.has("data") && data.get("data") != null) {
            returnValue = data.getString("data");
          }
        }

        if (data.get("type").equals("replace")) {
          if (data.has("data") && data.get("data") != null) {
            String rawString = data.getString("data");
            JSONObject replaceList = data.getJSONObject("replace");

            Iterator<String> keys = replaceList.keys();

            while (keys.hasNext()) {
              String key = keys.next();
              String str = ":" + key;

              if (replaceList.get(key) instanceof JSONArray) {
                if (rawString.contains(str)) {
                  JSONArray value = replaceList.getJSONArray(key);
                  rawString = rawString.replace(str, iterateCollection(structure, value));
                }
              }
            }
            returnValue = rawString;
          }

        }
      }

      return returnValue;
    } catch (Exception e) {
      e.printStackTrace();
      return "";
    }
  }

  private void saveEntries(JSONObject entries, String key, Context context) {
    SharedPreferences sharedPref = context.getSharedPreferences(GeofencingPrefs, reactContext.MODE_PRIVATE);
    SharedPreferences.Editor editor = sharedPref.edit();
    editor.putString(key, entries.toString());
    editor.apply();
  }

  private static void saveEntriesArray(JSONArray entries, String key, Context context) {
    SharedPreferences sharedPref = context.getSharedPreferences(GeofencingPrefs, reactContext.MODE_PRIVATE);
    SharedPreferences.Editor editor = sharedPref.edit();
    editor.putString(key, entries.toString());
    editor.apply();
  }

  public static JSONObject readEntries(Context context, String key) throws JSONException {
    SharedPreferences sharedPref = context.getSharedPreferences(GeofencingPrefs, reactContext.MODE_PRIVATE);
    String entries = sharedPref.getString(key, null);
    if (entries != null) {
      return new JSONObject(entries);
    }
    return null;
  }

  private static Boolean isFilteredValue(JSONObject structure, JSONObject data) throws JSONException {
    try {
      if (data.has("filter") && data.get("filter") != null) {
        if (structure.has(data.getJSONArray("filter").getString(0))) {
          String structureValue = structure.getString(data.getJSONArray("filter").getString(0));
          return structureValue.equals(data.getJSONArray("filter").getString(1));
        } else {
          return false;
        }
      }
    } catch (Exception e) {
      e.printStackTrace();
      return false;
    }
    return false;
  }

  private static String iterateCollection(JSONObject original, JSONArray iteratePath) throws JSONException {
    String returnValue = "";
    JSONObject filteredDataStructure = original;
    JSONArray filteredDataStructureArray = new JSONArray();

    for (int i = 0; i < iteratePath.length(); i++) {
      if (filteredDataStructure != null) {
        try {
          String path = iteratePath.getString(i);
          boolean iterate = filteredDataStructure.get(path) instanceof JSONArray || filteredDataStructure.get(path) instanceof JSONObject;

          if (iterate) {
            if (filteredDataStructure.has(path)) {
              if (filteredDataStructure.get(path) instanceof JSONArray) {
                filteredDataStructureArray = filteredDataStructure.getJSONArray(path);
                filteredDataStructure = null;
              } else if (filteredDataStructure.get(path) instanceof JSONObject) {
                filteredDataStructure = filteredDataStructure.getJSONObject(path);
                filteredDataStructureArray = null;
              }
            }
          } else {
            if (filteredDataStructure.has(path)) {
              returnValue = filteredDataStructure.getString(path);
              break;
            }
          }
        } catch (Exception e) {
          e.printStackTrace();
        }
      } else if (filteredDataStructureArray != null) {
        try {
          int path = iteratePath.getInt(i);
          boolean iterate = filteredDataStructureArray.get(path) instanceof JSONArray || filteredDataStructureArray.get(path) instanceof JSONObject;

          if (iterate) {
            if (filteredDataStructureArray.get(path) != null) {
              if (filteredDataStructureArray.get(path) instanceof JSONArray) {
                filteredDataStructureArray = filteredDataStructureArray.getJSONArray(path);
                filteredDataStructure = null;
              } else if (filteredDataStructureArray.get(path) instanceof JSONObject) {
                filteredDataStructure = filteredDataStructureArray.getJSONObject(path);
                filteredDataStructureArray = null;
              }
            }
          } else {
            if (filteredDataStructureArray.getString(path) != null) {
              returnValue = filteredDataStructureArray.getString(path);
              break;
            }
          }
        } catch (Exception e) {
          e.printStackTrace();
        }
      }
    }

    return returnValue;
  }

  public static JSONArray readEntriesArray(Context context, String key) throws JSONException {
    SharedPreferences sharedPref = context.getSharedPreferences(GeofencingPrefs, reactContext.MODE_PRIVATE);
    String entries = sharedPref.getString(key, null);
    if (entries != null) {
      return new JSONArray(entries);
    }
    return null;
  }

  private static PendingIntent getGeofencePendingIntent(Context context) {
    // Reuse the PendingIntent if we already have it.
    if (geofencePendingIntent != null) {
      return geofencePendingIntent;
    }
    Intent intent = new Intent(context, GeofenceBroadcastReceiver.class);
    // We use FLAG_UPDATE_CURRENT so that we get the same pending intent back when
    // calling addGeofences() and removeGeofences().
    geofencePendingIntent = PendingIntent.getBroadcast(context, 0, intent, PendingIntent.
      FLAG_UPDATE_CURRENT);
    return geofencePendingIntent;
  }

  private void createNotificationChannel(String channelId, String name, String description) {
    // Create the NotificationChannel, but only on API 26+ because
    // the NotificationChannel class is new and not in the support library
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      int importance = NotificationManager.IMPORTANCE_DEFAULT;
      NotificationChannel channel = new NotificationChannel(channelId, name, importance);
      channel.setDescription(description);
      // Register the channel with the system; you can't change the importance
      // or other notification behaviors after this
      NotificationManager notificationManager = reactContext.getApplicationContext().getSystemService(NotificationManager.class);
      notificationManager.createNotificationChannel(channel);
    }
  }
}
