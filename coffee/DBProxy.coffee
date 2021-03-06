moment = require "moment"
Proxy = require "encaps-proxy"
LOG = global["mongoLogger"] || console
###
# 数据库操作层代理
###
class DBProxy extends Proxy
	constructor: (target, security)->
		super(target, security)
		@dbname = target.url.substring (target.url.lastIndexOf('/') + 1), target.url.lastIndexOf('?')
	proxy: (f)->
		that = @
		if f.name is "connect"
			return ->
				f.apply that.target, arguments
		->
			[...params] = arguments
			callback = params.pop()
			startTime = moment()
			paramStr = ""
			paramStr = (JSON.stringify(p) for p in params).join ","
			paramStr = if paramStr.length > 100 then paramStr.substring(0, 200) + "..." else paramStr
			params.push ->
				endTime = moment()
				LOG.info "#{that.dbname}.#{that.collection}.#{f.name}:#{paramStr}  --#{endTime - startTime}ms"
				callback.apply @, arguments
			try
				f.apply that.target, params
			catch e
				(LOG.trace || LOG.error)("#{that.dbname}.#{that.collection}.#{f.name}:#{paramStr}  --#{moment() - startTime}ms\n#{e.stack}")
				callback e
module.exports = DBProxy
