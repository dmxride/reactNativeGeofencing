import { NativeModules, Platform } from 'react-native';
import type { IStartMonitoring, IPoi } from './types';

const LINKING_ERROR =
  `The package 'react-native-ubi-native-geofencing' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const UbiNativeGeofencing = NativeModules.UbiNativeGeofencing
  ? NativeModules.UbiNativeGeofencing
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function startMonitoring(
  dataStructure: IStartMonitoring
): Promise<boolean> {
  return UbiNativeGeofencing.startMonitoring(dataStructure);
}

export function stopMonitoring(): Promise<boolean> {
  return UbiNativeGeofencing.stopMonitoring();
}

export function addPois(poistList: IPoi[]): Promise<boolean> {
  return UbiNativeGeofencing.addPois(poistList);
}
