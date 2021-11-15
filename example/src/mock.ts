export const monitoringMockStructure = {
  channelId: 'geoparque_geofence_channel',
  channelName: 'Geoparque Geofence Channel',
  channelDescription: 'Channel for geoparque geofences',
  startNotification: {
    title: 'Started Title',
    description: 'Started Description',
    deepLink: 'geoparque://app/geofence',
  },
  //....auto location BGsearch integration......
  watchSelfLocation: true,
  poiURL:
    'https://geoparquelitoralviana.pt/api/v2/pois/?title_search=&only_points=true&categories=8,4,6,7&radius=:radius&lat=:latitude&long=:longitude',
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
          data: 'https://geoparquelitoralviana.pt/:url',
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
          data: 'A entrar no monumento :title',
          replace: {
            title: ['title'],
          },
        },
        exitTitle: {
          type: 'string',
          data: 'A sair do monumento :title',
          filter: ['parent', 'null'],
        },
        exitMessage: {
          type: 'string',
          data: 'A sair do monumento',
          filter: ['parent', 'null'],
        },
      },
    },
  ],
};
