package com.geoparque_vc;

import android.app.ActivityManager;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.net.Uri;
import android.os.AsyncTask;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import android.os.Build;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;

/*
..Async task PATTERN
*/
public class Notifications extends AsyncTask<String, Void, Bitmap> {

    private Context ctx;
    private String title, desc, image, channelId, deepLink;
    private Integer notificationId;
    private Integer poiID;

    public Notifications(Context context, String channelId, Integer notificationId, String title, String desc, String image, String deepLink, Integer poiID) {
        super();
        this.ctx = context;
        this.channelId = channelId;

        if (notificationId == null) {
            this.notificationId = 1;
        } else {
            this.notificationId = 1 + notificationId;
        }

        this.poiID = poiID;
        this.deepLink = deepLink != null ? deepLink : "";
        this.title = title != null ? title : "";
        this.desc = desc != null ? desc : "";
        this.image = image;
    }

    @RequiresApi(api = Build.VERSION_CODES.CUPCAKE)
    @Override
    protected void onPostExecute(Bitmap result) {
        super.onPostExecute(result);
        NotificationCompat.Builder builder;


        if (result != null) {
            builder = new NotificationCompat.Builder(ctx, channelId)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setContentTitle(title)
                    .setContentText(desc)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setLargeIcon(result)
                    .setVibrate(new long[]{1000, 1000, 1000, 1000})
                    .setLights(Color.GREEN, 3000, 3000)
                    .setStyle(new NotificationCompat.BigPictureStyle().bigPicture(result).bigLargeIcon(null))
                    .setAutoCancel(true);
        } else {
            builder = new NotificationCompat.Builder(ctx, channelId)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setContentTitle(title)
                    .setContentText(desc)
                    .setVibrate(new long[]{1000, 1000, 1000, 1000})
                    .setLights(Color.GREEN, 3000, 3000)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setAutoCancel(true);
        }

        if(this.deepLink !=null){
            Intent notificationIntent = new Intent(Intent.ACTION_VIEW);
            notificationIntent.setData(Uri.parse(this.deepLink));
            notificationIntent.addFlags(Intent.FLAG_ACTIVITY_TASK_ON_HOME);
            notificationIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
            notificationIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
            PendingIntent notifyPendingIntent = PendingIntent.getActivity(ctx, 0, notificationIntent, 0);
            builder.setContentIntent(notifyPendingIntent);
        }

        NotificationManager notificationManager = (NotificationManager) ctx.getSystemService(Service.NOTIFICATION_SERVICE);

        // notificationId is a unique int for each notification that you must define
        notificationManager.notify(notificationId, builder.build());
    }

    public static boolean isAppRunning(final Context context, final String packageName) {
        final ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        final List<ActivityManager.RunningAppProcessInfo> procInfos = activityManager.getRunningAppProcesses();
        if (procInfos != null)
        {
            for (final ActivityManager.RunningAppProcessInfo processInfo : procInfos) {
                if (processInfo.processName.equals(packageName)) {
                    return true;
                }
            }
        }
        return false;
    }


    @Override
    protected Bitmap doInBackground(String... params) {
        InputStream in;
        if (this.image != null) {
            try {
                URL url = new URL(this.image);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setDoInput(true);
                connection.connect();
                in = connection.getInputStream();
                Bitmap myBitmap = BitmapFactory.decodeStream(in);
                return myBitmap;
            } catch (MalformedURLException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return null;
    }

}
