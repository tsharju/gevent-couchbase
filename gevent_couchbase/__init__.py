import gevent

from gevent_couchbase.core import couchbase

# so that gevent starts the event loop
hub = gevent.get_hub()


class CouchbaseClient(gevent.Greenlet):

    def __init__(self, *args, **kwargs):
        gevent.Greenlet.__init__(self)

        self._conn = couchbase.Couchbase(
            '192.168.100.17',
            'Administrator',
            'testtest')

    def _run(self):
        i = 0
        while True:
            gevent.sleep(5)
            self._conn.set('loop', "%d" % i, self.set)
            i += 1
    
    def set(self, result):
        print "SET CALLBACK: " + result
