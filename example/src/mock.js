export const monitoringMockStructure = {
  channelId: 'geofence_channel',
  channelName: 'Channel',
  channelDescription: 'Channel for geofences',
  startNotification: {
    title: 'Started Title',
    description: 'Started Description',
    deepLink: 'link://app/deeplink',
  },
  //....auto location BGsearch integration......
  watchSelfLocation: true,
  poiURL:
    'https://api_url/api/v2/pois/?title_search=&only_points=true&categories=8,4,6,7&radius=:radius&lat=:latitude&long=:longitude',
  fetchRadius: 0.4,
  filter: [['poi', 'poiId', '=']],
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
          data: 'A sair de',
          filter: ['parent', 'null'],
        },
      },
    },
  ],
};
