export interface IStartMonitoring {
  channelId: String;
  channelName: String;
  channelDescription: String;
  startNotification: {
    title: String;
    description: String;
    deepLink: String;
  };
  //....auto location BGsearch integration......
  watchSelfLocation: Boolean;
  poiURL: String;
  fetchRadius: Number;
  dataStructure: {
    main: String[];
    poi: {
      poiId: unionUse;
      latitude: unionUse;
      longitude: unionUse;
      radius: unionUse;
      largeIcon: unionUse;
      deepLink: unionUse;
      enterTitle: unionUse;
      enterMessage: unionUse;
      exitTitle: unionUse;
      exitMessage: unionUse;
    };
  }[];
}

export interface IPoi {
  poiId: Number;
  key: String;
  latitude: String;
  longitude: String;
  radius: Number;
  largeIcon: String;
  enterTitle: String;
  enterMessage: String;
  exitTitle: String;
  exitMessage: String;
}

type unionUse = {
  type: any;
  data: any;
  filter?: any;
  replace?: any;
};

/*interface useString {
  type: 'string';
  data: String[];
  filter?: String[];
}

interface useReplace {
  type: 'replace';
  data: String;
  replace: {
    [key: string]: String[];
  };
}

interface useNumber {
  type: 'number';
  data: Number;
}

interface usePath {
  type: 'path';
  data: String[];
}
*/
