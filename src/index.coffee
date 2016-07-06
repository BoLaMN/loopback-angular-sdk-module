'use strict'

angular.module 'loopback.provider', [ ]

.provider 'LoopBackResource', ($provide) ->
  config = undefined

  construct = ($injector, $resource) ->

    create = (modelName, options, config) ->

      transformResponse = (scopeNames, scopes) ->

        models = (data) ->
          scopeNames.forEach (scopeName) ->
            scope = scopes[scopeName]

            if data[scopeName]
              modelObject = $injector.get(modelName)[scopeName]

              if angular.isArray data[scopeName]
                angular.forEach data[scopeName], (object, index) ->
                  data[scopeName][index] = new modelObject object
                  return
              else
                data[scopeName] = new modelObject data[scopeName]

          data

        (jsonData) ->
          newData = JSON.parse jsonData

          if angular.isArray(newData) and newData.length
            data = newData.map models
          else
            data = models newData

          data

      transformRequest = (scopeNames, scopes) ->

        clean = (data) ->
          dta = {}

          angular.forEach data, (value, key, obj) ->
            if angular.isUndefined value
              return

            if key is '_scopeMeta'
              return

            if angular.isFunction value
              return

            if value is null
              return

            if angular.isArray(value) and not value?.length
              return

            if value.prototype?.constructor?.name is 'Resource'
              return

            @[key] = value
          , dta

          dta

        (resourceData) ->
          if angular.isArray resourceData
            data = resourceData.map clean
          else
            console.log resourceData, 'not array'
            data = clean resourceData

          angular.toJson data

      transformMethods = (options) ->
        if angular.isObject options.scopes
          scopeNames = Object.keys(options.scopes)

          Object.keys(options.methods).forEach (methodName) ->
            method = options.methods[methodName]

            method.url = config.url + method.url

            if method.method is 'get'
              method.transformResponse = transformResponse scopeNames, options.scopes

            if method.method in [ 'put', 'post', 'patch' ]
              method.transformRequest = transformRequest scopeNames, options.scopes
              method.transformResponse = transformResponse scopeNames, options.scopes

            options.methods[methodName] = method

        options.methods

      resource = $resource config.url + options.url, options.params, transformMethods(options)

      methods = (scoped) ->
        if angular.isObject scoped
          Object.keys(scoped).forEach (scopeName) ->
            if scopeName is ''
              return

            if scopeName is 'get'
              scopeName = 'find'

            resource[scopeName] = create modelName, scoped[scopeName], config

        this

      methods options.scopes

      resource::$save = ->
        action = if @id then '$updateById' else '$create'
        @[action]()

      resource::delete = ->
        if !@id
          throw new Error('Object must have an id to be deleted.')

        @$destroy id: @id

      resource

    create

  registerModels: (url) ->
    if url
      config.url = url

    Object.keys(config.models).forEach (modelName) ->
      $provide.factory modelName, [
        '$injector', '$resource', ($injector, $resource) ->
          construct($injector, $resource)(modelName,  config.models[modelName], config)
      ]

  getUrlBase: ->
    config.url

  setConfig: (newConfig) ->
    config = newConfig

  $get: angular.noop
