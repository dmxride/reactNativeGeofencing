import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import {
  startMonitoring,
  stopMonitoring,
} from 'react-native-ubi-native-geofencing';

import { monitoringMockStructure } from './mock';

export default function App() {
  const [isMonitoring, setIsMonitoring] = React.useState(false);

  const startTracking = () => {
    startMonitoring(monitoringMockStructure)
      .then(() => {
        console.log('GEOFENCING STARTED MONITORING');
        setIsMonitoring(true);
      })
      .catch((e) => {
        console.log('AN ERROR HAS OCURRED WITH GEOFENCING MONITORING');
        console.error(e);
      });
  };

  const stopTracking = () => {
    stopMonitoring()
      .then(() => {
        console.log('GEOFENCING STOPPED MONITORING');
        setIsMonitoring(false);
      })
      .catch((e) => {
        console.log('AN ERROR HAS OCURRED WITH GEOFENCING MONITORING');
        console.error(e);
      });
  };

  return (
    <View style={styles.container}>
      {!isMonitoring ? (
        <TouchableOpacity style={styles.button} onPress={startTracking}>
          <Text>Start Monitoring</Text>
        </TouchableOpacity>
      ) : (
        <TouchableOpacity style={styles.button} onPress={stopTracking}>
          <Text>Stop Monitoring</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#000003',
  },
  button: {
    height: 30,
    paddingHorizontal: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFF66',
  },
});
