# react-native-custom-native-geofencing

Native geofencing integration with react-native, works while in background for both Android and iOS devices.

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

# Installation

## Adding the library

With npm:

```sh
npm install --save react-native-custom-native-geofencing
```

With yarn:

```sh
yarn add react-native-custom-native-geofencing
```

## Linking

If you are using **React Native 0.60+** follow this steps, for previous versions check the [Manual Linking](#manualLinkingStep) step.

**Android & iOS**

[CLI autolink feature](https://github.com/react-native-community/cli/blob/master/docs/autolinking.md) links the module while building the app.

On iOS, use CocoaPods to add react-native-custom-native-geofencing to your project:

```sh
react-native link react-native-custom-native-geofencing --platforms ios
cd ios && npx pod-install
```

### **React Native <= 0.59**

```sh
react-native link react-native-custom-native-geofencing
```

## <a name="manualLinkingStep"></a>Manual Linking

### iOS

---

#### **Project linking :**

1.  Open your project `.xcodeproj` on xcode.
2.  Right click on the Libraries folder and select `Add files to "yourProjectName"`.
3.  Add `NativeGeofencing.xcodeproj` (located at `node_modules/nativeGeofencing/ios`) to your project Libraries.
4.  Go to `Build Phases -> Link Binary with Libraries` and add: `libNativeGeofencing.a`.

---

#### **Using Pods :**

1.  Enter into iOS Folder `cd ios/` (on your project's root folder).
2.  Add this line to your `Podfile` just below the last pod (if you don't have one, you can create it by running `pod init`):

```sh
pod 'react-native-custom-native-geofencing', :path => '../node_modules/react-native-custom-native-geofencing'
```

3. Run

```sh
pod install
```

### Android

---

1.  Add project to `android/settings.gradle`:

```java
include ':react-native-custom-native-geofencing'

project(':react-native-custom-native-geofencing').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-custom-native-geofencing/android')
```

2.  In `android/app/build.gradle` add to dependencies:

```java
dependencies {
  ...
  implementation project(':@react-native-async-storage')
}
```

3.  Then, in `android/app/src/main/java/your/package/MainApplication.java`:

```java
import com.reactnativecustomnativegeofencing.NativeGeofencingPackage;

...

@Overrideprotected List<ReactPackage> getPackages() {
  return Arrays.<ReactPackage>asList(
    ...
    new NativeGeofencingPackage()
  );
}
```

## Integration

### Android

---

1. Simply add this to your `AndroidManifest.xml` inside the `<application>` tag:

```java
<receiver android:name="com.reactnativecustomnativegeofencing.GeofenceBroadcastReceiver" />
```

### iOS

---

1. Inside your `AppDelegate.m` import the header file

```objective-c
 #import <react-native-custom-native-geofencing/GeofencingModuleDelegate.h>
```

2. Inside your delegate `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` insert this before the `return` statement:

```objective-c
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  ...

  [GeofencingModuleDelegate start];

  return YES;
}
```

3. Update your Info.plist bu adding `NSLocationAlwaysAndWhenInUseUsageDescription` and `NSLocationWhenInUseUsageDescription` keys.

4. Add or update the background modes capabilities with the following settings:

![BgModes1](./readme/bgModes_1.png)
![BgModes2](./readme/bgModes2.png)

# Usage

```typescript
import {
  startMonitoring,
  addPois,
  stopMonitoring,
} from 'react-native-custom-native-geofencing';

startMonitoring(monitoringDataStructure)
      .then(() => {
        // GEOFENCING STARTED MONITORING
      })
      .catch((e) => {
         // AN ERROR HAS OCURRED WITH GEOFENCING MONITORING
      });
  };

  stopMonitoring()
      .then(() => {
        // GEOFENCING STOPPED MONITORING
      })
      .catch((e) => {
        // AN ERROR HAS OCURRED WITH GEOFENCING MONITORING
      });


  addPois([])
      .then(() => {
         // GEOFENCING POIS ADDED
      })
      .catch((e) => {
        // AN ERROR HAS OCURRED ADDING POIS
      });

```

# API

## `startMonitoring`

---

Starts monitoring for location changes, it also supports a structured Object with API parameters to automatically update your geofencing areas. According to iOS API there is a limit of 20 geofences you can have at a same time and according to the Android API that limits goes to up to 100.

Everytime the user exits a geofence or a defined radius the number of points will be updated according to the defined Object parameter.

### **Signature:**

```typescript
static startMonitoring(startStructure: StartStructure): Promise
```

### **Returns:**

Promise resolving with no given values, if the monitoring service successfully started.

Promise can also be rejected in case of an error.

### **Example:**

```typescript

import {
  startMonitoring
} from 'react-native-custom-native-geofencing';


const startStructure = {
  channelId: 'geofence_channel',
  channelName: 'Geofence Channel',
  channelDescription: 'Channel for geofences',
  startNotification: {
    title: 'Started Title',
    description: 'Started Description',
    //adds a deeplink to your notification on click
    deepLink: 'deeplink://app/link',
  },
  //....auto location BGsearch integration......
  watchSelfLocation: true,
  poiURL:
    'https://api_url/api/v2/pois/?title_search=&only_points=true&categories=8,4,6,7&radius=:radius&lat=:latitude&long=:longitude',
  fetchRadius: 0.4,
  dataStructure: [
    {
      main: ['items'],
      poi: {
        poiId: {
          type: 'path',
          data: ['id'],
        },
        latitude: {
          type: 'path',
          data: ['location_lat'],
        },
        longitude: {
          type: 'path',
          data: ['location_long'],
        },
        radius: {
          type: 'number',
          data: 100,
        },
        largeIcon: {
          type: 'replace',
          data: 'https://media_url/:url',
          replace: {
            url: ['feature_image', 'medium_size', 'url'],
          },
        },
        deepLink: {
          type: 'path',
          data: ['deep_link_url'],
        },
        enterTitle: {
          type: 'path',
          data: ['title'],
        },
        enterMessage: {
          type: 'replace',
          data: 'A entrar em :title',
          replace: {
            title: ['title'],
          },
        },
        exitTitle: {
          type: 'string',
          data: 'A sair de :title',
          filter: ['parent', 'null'],
        },
        exitMessage: {
          type: 'string',
          data: 'A sair',
          filter: ['parent', 'null'],
        },
      },
    },
  ],
};

startMonitoring(startStructure)
      .then(() => {
        // GEOFENCING STARTED MONITORING
      })
      .catch((e) => {
         // AN ERROR HAS OCURRED WITH GEOFENCING MONITORING
      });
  };


```

### **Properties :**

| startStructure Props                         | Description | Type                                |
| -------------------------------------------- | ----------- | ----------------------------------- |
| channelId                                    | ""          | `String`                            |
| channelName                                  | ""          | `String`                            |
| channelDescription                           | ""          | `String`                            |
| [startNotification](#startNotificationProps) | ""          | [`Object`](#startNotificationProps) |
| watchSelfLocation                            | ""          | `Boolean`                           |
| poiURL                                       | ""          | `String`                            |
| fetchRadius                                  | ""          | `Number`                            |
| [dataStructure](#dataStructureProps)         | ""          | [`Object[]`](#dataStructureProps)   |

<a name="startNotificationProps"></a>
| startNotification Props | Description | Type |
| ------------------- | ----------- | ---- |
| title | "" |`String` |
| description | "" | `String` |
| deepLink | "" | `String` |

<a name="dataStructureProps"></a>
| dataStructure Props | Description | Type |
| ------------------- | ----------- | ---- |
| main | "" | `String[]` |
| [poi](#poiStructureProps) | "" | [`Object[]`](#poiStructureProps) |

<a name="poiStructureProps"></a>
| poi Props | Description | Type |
| ------------ | ----------- | ---- |
| poiId | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| latitude | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| longitude | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| radius | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| largeIcon | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| deepLink | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| enterTitle | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| enterMessage | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| exitTitle | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |
| exitMessage | "" | [`useString`](#useStringProps) \| [`useReplace`](#useReplaceProps) \| [`useNumber`](#useNumberProps) \| [`usePath`](#usePathProps) |

<a name="useStringProps"></a>
| useString Props | Description | Type |
| ------------------- | ----------- | ---- |
| type | "" | `'string'` |
| data | "" | `String[]`|
| filter | "" | `?String[]`|

<a name="useReplaceProps"></a>
| useReplace Props | Description | Type |
| ------------------- | ----------- | ---- |
| type | "" | `'replace'` |
| data | "" | `String`|
| fireplacelter | "" | `{ [key: string]: String[]; }`|

<a name="useNumberProps"></a>
| useNumber Props | Description | Type |
| ------------------- | ----------- | ---- |
| type | "" | `'number'` |
| data | "" | `Number`|

<a name="usePathProps"></a>
| usePath Props | Description | Type |
| ------------------- | ----------- | ---- |
| type | "" | `'path'` |
| data | "" | `String[]`|

## `stopMonitoring`

---

Stop monitoring for location changes and removes every defined background listener service.

### **Signature:**

```typescript
static stopMonitoring(): Promise
```

### **Returns:**

Promise resolving with no given values, if the monitoring service successfully stopped.

Promise can also be rejected in case of an error.

### **Example:**

```typescript

import {
  stopMonitoring
} from 'react-native-custom-native-geofencing';

stopMonitoring()
      .then(() => {
        // GEOFENCING STOPPED MONITORING
      })
      .catch((e) => {
         // AN ERROR HAS OCURRED WITH GEOFENCING MONITORING
      });
  };


```

## `addPois`

---

Add points of interest (Pois), geofences, to an already started monitoring session for location changes. If used after setting an Object data structure in startMonitoring, the defined geofences will be erased after automatic background location updates.

### **Signature:**

```typescript
static addPois(pois:Poi[]): Promise
```

### **Returns:**

Promise resolving with no given values, if the geofences where successfully added.

Promise can also be rejected in case of an error.

### **Example:**

```typescript

import {
  addPois
} from 'react-native-custom-native-geofencing';

const poisStructure = [
 {
    poiId: 1,
    key: 'poi_number_1',
    latitude: '40.6468699',
    longitude: '-8.6432191',
    radius: '100',
    largeIcon: 'iconToUse.jpg',
    enterTitle: 'Enter notification title',
    enterMessage: 'Enter notification message',
    exitTitle: 'Exit notification title',
    exitMessage: 'Exit notification message'
 },
 {
    poiId: 2,
    key: 'poi_number_2',
    latitude: '40.64271',
    longitude: '-8.6599377',
    radius: '100',
    largeIcon: 'iconToUse.jpg',
    enterTitle: 'Enter notification title',
    enterMessage: 'Enter notification message',
    exitTitle: 'Exit notification title',
    exitMessage: 'Exit notification message'
 }
]

addPois(poisStructure)
      .then(() => {
        // GEOFENCING STOPPED MONITORING
      })
      .catch((e) => {
         // AN ERROR HAS OCURRED WITH GEOFENCING MONITORING
      });
  };


```

# Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

# License

MIT
