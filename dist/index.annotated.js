'use strict';
angular.module('loopback.provider', []).provider('LoopBackResource', ["$provide", function($provide) {
  var config, construct;
  config = void 0;
  construct = function($injector, $resource) {
    var create;
    create = function(modelName, options, config) {
      var methods, resource, transformMethods, transformRequest, transformResponse;
      transformResponse = function(scopeNames, scopes) {
        var models;
        models = function(data) {
          scopeNames.forEach(function(scopeName) {
            var modelObject, scope;
            scope = scopes[scopeName];
            if (data[scopeName]) {
              modelObject = $injector.get(modelName)[scopeName];
              if (angular.isArray(data[scopeName])) {
                return angular.forEach(data[scopeName], function(object, index) {
                  data[scopeName][index] = new modelObject(object);
                });
              } else {
                return data[scopeName] = new modelObject(data[scopeName]);
              }
            }
          });
          return data;
        };
        return function(jsonData) {
          var data, newData;
          newData = JSON.parse(jsonData);
          if (angular.isArray(newData) && newData.length) {
            data = newData.map(models);
          } else {
            data = models(newData);
          }
          return data;
        };
      };
      transformRequest = function(scopeNames, scopes) {
        var clean;
        clean = function(data) {
          var dta;
          dta = {};
          angular.forEach(data, function(value, key, obj) {
            var ref, ref1;
            if (angular.isUndefined(value)) {
              return;
            }
            if (key === '_scopeMeta') {
              return;
            }
            if (angular.isFunction(value)) {
              return;
            }
            if (value === null) {
              return;
            }
            if (angular.isArray(value) && !(value != null ? value.length : void 0)) {
              return;
            }
            if (((ref = value.prototype) != null ? (ref1 = ref.constructor) != null ? ref1.name : void 0 : void 0) === 'Resource') {
              return;
            }
            return this[key] = value;
          }, dta);
          return dta;
        };
        return function(resourceData) {
          var data;
          if (angular.isArray(resourceData)) {
            data = resourceData.map(clean);
          } else {
            console.log(resourceData, 'not array');
            data = clean(resourceData);
          }
          return angular.toJson(data);
        };
      };
      transformMethods = function(options) {
        var scopeNames;
        if (angular.isObject(options.scopes)) {
          scopeNames = Object.keys(options.scopes);
          Object.keys(options.methods).forEach(function(methodName) {
            var method, ref;
            method = options.methods[methodName];
            method.url = config.url + method.url;
            if (method.method === 'get') {
              method.transformResponse = transformResponse(scopeNames, options.scopes);
            }
            if ((ref = method.method) === 'put' || ref === 'post' || ref === 'patch') {
              method.transformRequest = transformRequest(scopeNames, options.scopes);
              method.transformResponse = transformResponse(scopeNames, options.scopes);
            }
            return options.methods[methodName] = method;
          });
        }
        return options.methods;
      };
      resource = $resource(config.url + options.url, options.params, transformMethods(options));
      methods = function(scoped) {
        if (angular.isObject(scoped)) {
          Object.keys(scoped).forEach(function(scopeName) {
            if (scopeName === '') {
              return;
            }
            if (scopeName === 'get') {
              scopeName = 'find';
            }
            return resource[scopeName] = create(modelName, scoped[scopeName], config);
          });
        }
        return this;
      };
      methods(options.scopes);
      resource.prototype.$save = function() {
        var action;
        action = this.id ? '$updateById' : '$create';
        return this[action]();
      };
      resource.prototype["delete"] = function() {
        if (!this.id) {
          throw new Error('Object must have an id to be deleted.');
        }
        return this.$destroy({
          id: this.id
        });
      };
      return resource;
    };
    return create;
  };
  return {
    registerModels: function(url) {
      if (url) {
        config.url = url;
      }
      return Object.keys(config.models).forEach(function(modelName) {
        return $provide.factory(modelName, [
          '$injector', '$resource', function($injector, $resource) {
            return construct($injector, $resource)(modelName, config.models[modelName], config);
          }
        ]);
      });
    },
    getUrlBase: function() {
      return config.url;
    },
    setConfig: function(newConfig) {
      return config = newConfig;
    },
    $get: angular.noop
  };
}]);
