import JSONAPIAdapter from 'ember-data/adapters/json-api';
import DataAdapterMixin from 'ember-simple-auth/mixins/data-adapter-mixin';
import config from 'frontend/config/environment';

export default JSONAPIAdapter.extend(DataAdapterMixin, {
  host: config.apiUrl,
  namespace: config.apiNamespace,
  authorizer: 'authorizer:application'
});
