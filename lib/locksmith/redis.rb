require 'timeout'
require 'thread'
require 'locksmith/config'
require 'securerandom'

module Locksmith
  module Redis
    extend self

    def lock(name, opts={})
      opts[:ttl] ||= 60
      opts[:attempts] ||= 3
      id = SecureRandom.uuid

      if create(name, opts[:ttl], id)
        begin Timeout::timeout(opts[:ttl]) {return(yield)}
        ensure delete(name, id)
        end
      end
    end

    def create(name, ttl, id)
      redis.setnx(name, id)
      redis.expire(name, ttl)
    end

    def delete(name, id)
      redis.watch(name) do
        if redis.get(name) == id
          redis.multi do
            redis.delete(name)
          end
          true
        else
          redis.unwatch
          false
        end
      end
    end

    def redis
      @redis ||= ::Redis.new
    end
  end
end
