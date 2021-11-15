package com.geoparque_vc;

import io.sentry.Sentry;

import static com.geoparque_vc.nativeModules.GeofencingModule.readEntries;
import static com.geoparque_vc.nativeModules.GeofencingModule.readEntriesArray;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.location.Location;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;
import com.geoparque_vc.nativeModules.GeofencingModule;
import com.geoparque_vc.nativeModules.ReactNativeJson;
import com.geoparque_vc.nativeModules.SingleShotLocationProvider;
import com.google.android.gms.location.Geofence;
import com.google.android.gms.location.GeofenceStatusCodes;
import com.google.android.gms.location.GeofencingEvent;
import com.google.gson.Gson;


import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

public class GeofenceBroadcastReceiver extends BroadcastReceiver {
  public void onReceive(Context context, Intent intent) {
    try {
      Log.d("GEOFENCE", "Receiving");

      Sentry.capture("GEOFENCE EVENT DETECTED");

      Sentry.capture("CURRENT GEOFENCES:");
      JSONArray geofenceEntries = readEntriesArray(context, "geofenceEntries");
      Sentry.capture(geofenceEntries.toString());

        GeofencingEvent geofencingEvent = GeofencingEvent.fromIntent(intent);
      if (geofencingEvent.hasError()) {
        String errorMessage = GeofenceStatusCodes
            .getStatusCodeString(geofencingEvent.getErrorCode());
        return;
      }

      // Get the transition type.
      int geofenceTransition = geofencingEvent.getGeofenceTransition();

      // Test that the reported transition was of interest.
      if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER ||
          geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {

        // Get the geofences that were triggered. A single event can trigger
        // multiple geofences.
        List<Geofence> triggeringGeofences = geofencingEvent.getTriggeringGeofences();
        Log.d("GEODETAILS TRIGGERS", triggeringGeofences.toString());

        // Get the transition details as a String.
        List geofenceTransitionDetails = null;
        try {
          geofenceTransitionDetails = getGeofenceTransitionDetails(context, triggeringGeofences);
        } catch (JSONException e) {
          e.printStackTrace();
        }

        Log.d("GEODETAILS ENTER", geofenceTransitionDetails.toString());
        for (Object geofenceEntry : geofenceTransitionDetails) {

          JSONObject entry = null;
          try {
            entry = new JSONObject(new Gson().toJson(geofenceEntry)).getJSONObject("nameValuePairs");
          } catch (JSONException e) {
            e.printStackTrace();
          }

          boolean sendNotification = false;

          String notTitle = "";
          String notMessage = "";
          String notIcon = "";
          String deepLink = null;
          Integer notId = null;
          Integer poiID = null;

          if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {
            Sentry.capture("EXITING GEOFENCE");
            Log.d("GEODETAILS EXIT", geofenceTransitionDetails.toString());

            Promise promise = new Promise() {
              @Override
              public void resolve(@Nullable Object value) {

              }

              @Override
              public void reject(String code, String message) {

              }

              @Override
              public void reject(String code, Throwable throwable) {

              }

              @Override
              public void reject(String code, String message, Throwable throwable) {

              }

              @Override
              public void reject(Throwable throwable) {

              }

              @Override
              public void reject(Throwable throwable, WritableMap userInfo) {

              }

              @Override
              public void reject(String code, @Nonnull WritableMap userInfo) {

              }

              @Override
              public void reject(String code, Throwable throwable, WritableMap userInfo) {

              }

              @Override
              public void reject(String code, String message, @Nonnull WritableMap userInfo) {

              }

              @Override
              public void reject(String code, String message, Throwable throwable, WritableMap userInfo) {

              }

              @Override
              public void reject(String message) {

              }
            };

            Sentry.capture("EXITING GEOFENCE");

            if (entry.has("poiId")) {
              Sentry.capture("GEOFENCE POIID: " + entry.getString("poiId"));
            }

            if (entry.has("enterTitle")) {
              Sentry.capture("GEOFENCE ENTER TITLE: " + entry.getString("enterTitle"));
            }

            SingleShotLocationProvider.requestSingleUpdate(context,
                new SingleShotLocationProvider.LocationCallback() {
                  @Override
                  public void onNewLocationAvailable(Location location) throws JSONException {
                    GeofencingModule.configPoiFromMe(promise, context, location);
                  }
                });


            //Location l = geofencingEvent.getTriggeringLocation();
            //GeofencingModule.configPoiFromMe(promise, context, l);

            if (entry.has("exitTitle") || entry.has("exitMessage")) {
              sendNotification = true;
              if (entry.has("exitTitle")) {
                notTitle = entry.getString("exitTitle");
              }
              if (entry.has("exitMessage")) {
                notMessage = entry.getString("exitMessage");
              }
            }

          }

          Log.d("DEBUG ENTRY", entry.toString());
          if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER) {
            Sentry.capture("ENTERING GEOFENCE");

            if (entry.has("enterTitle") || entry.has("enterMessage")) {
              sendNotification = true;
              if (entry.has("enterTitle")) {
                Sentry.capture("GEOFENCE ENTER TITLE: " + entry.getString("enterTitle"));
                notTitle = entry.getString("enterTitle");
              }
              if (entry.has("enterMessage")) {
                notMessage = entry.getString("enterMessage");
              }
            }

          }

          if (entry.has("largeIcon")) {
            notIcon = entry.getString("largeIcon");
          }

          if (entry.has("notificationId")) {
            notId = Double.valueOf(entry.getString("notificationId")).intValue();
          }

          if (entry.has("poiId")) {
            Sentry.capture("GEOFENCE POIID: " + entry.getString("poiId"));
            poiID = Double.valueOf(entry.getString("poiId")).intValue();
          }

          if (entry.has("deepLink")) {
            Sentry.capture("GEOFENCE DEEPLINK: " + entry.getString("deepLink"));
            deepLink = entry.getString("deepLink");
          }

          if (sendNotification) {
            // Send notification and log the transition details.
            try {
              sendNotification(notId, notTitle, notMessage, notIcon, deepLink, context, poiID);
            } catch (JSONException e) {
              e.printStackTrace();
            }
          }
        }
      }
    } catch (JSONException e) {
      e.printStackTrace();
    }
  }

  private ArrayList getGeofenceTransitionDetails(Context context, List<Geofence> triggeringGeofences) throws JSONException {
    // Get the Ids of each geofence that was triggered.
    ArrayList triggeringGeofenceList = new ArrayList();

    for (Geofence geofence : triggeringGeofences) {
      JSONArray geofenceEntries = readEntriesArray(context, "geofenceEntries");
      Log.d("GEODETAILS ALL", geofenceEntries.toString());

      for (int i = 0; i < geofenceEntries.length(); i++) {
        JSONObject entry = geofenceEntries.getJSONObject(i);

        if (entry.get("key").equals(geofence.getRequestId())) {
          triggeringGeofenceList.add(entry);
        }
      }
    }

    return triggeringGeofenceList;
  }

  public static void sendNotification(int notificationId, String notificationTitle, String notificationDetails, String image, String deepLink, Context context, int poiID) throws JSONException {
    JSONObject entry = readEntries(context, "channelOptions");
    new Notifications(context, entry.getString("channelId"), notificationId, notificationTitle, notificationDetails, image, deepLink, poiID).execute();
  }
}
