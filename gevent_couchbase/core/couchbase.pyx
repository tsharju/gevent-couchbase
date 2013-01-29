from libc.string cimport memset, strlen

from libcouchbase cimport *

cdef extern from "Python.h":
    int PyString_AsStringAndSize(object obj, char **s, Py_ssize_t *len) except -1
    object PyString_FromStringAndSize(char *v, Py_ssize_t len)

cdef extern from "ev.h":
    struct ev_loop:
        pass
    ev_loop* ev_default_loop(unsigned int flags)
    void ev_run(ev_loop *loop, int flags)

cdef void error_handler(lcb_t instance, lcb_error_t err, char *info):
    raise Exception("FATAL: " + lcb_strerror(instance, err))

cdef void store_handler(lcb_t instance, void *cookie, lcb_storage_t operation,
                        lcb_error_t error, lcb_store_resp_t *resp):
    cdef object key

    print "Store callback called"

    if resp.version == 0:
        key = PyString_FromStringAndSize(<char*>resp.v.v0.key,
                                          resp.v.v0.nkey)
        (<object>cookie)(key)

cdef void get_handler(lcb_t instance, void *cookie, lcb_error_t error,
                      lcb_get_resp_t *resp):
    cdef object key
    cdef object value

    if resp.version == 0:
        key = PyString_FromStringAndSize(<char*>resp.v.v0.key,
                                          resp.v.v0.nkey)
        value = PyString_FromStringAndSize(<char*>resp.v.v0.bytes,
                                            resp.v.v0.nbytes)
        (<object>cookie)(key, value)
        

class AuthenticationError(Exception):
    pass


cdef class Couchbase:

    cdef lcb_t instance
    cdef lcb_create_st options

    def __cinit__(self, host, user=None, passwd=None, bucket=None):
        cdef lcb_error_t error
        cdef lcb_create_io_ops_st io_opts
        cdef ev_loop *loop

        loop = ev_default_loop(0)

        memset(&io_opts, 0, sizeof(io_opts))

        io_opts.version = 1
        io_opts.v.v1.sofile = NULL
        io_opts.v.v1.symbol = "lcb_create_libev_io_opts"
        io_opts.v.v1.cookie = loop

        memset(&self.options, 0, sizeof(self.options))

        error = lcb_create_io_ops(&self.options.v.v0.io, &io_opts)
        if error != LCB_SUCCESS:
            raise ValueError("Failed to create IO ops: " + \
                                 lcb_strerror(self.instance, error))

        self.options.version = 0
        self.options.v.v0.host = host

        if user is not None:
            self.options.v.v0.user = user
        if passwd is not None:
            self.options.v.v0.passwd = passwd
        if bucket is not None:
            self.options.v.v0.bucket = bucket

        error = lcb_create(&self.instance, &self.options)
        if error != LCB_SUCCESS:
            raise ValueError(lcb_strerror(self.instance, error))

        lcb_behavior_set_syncmode(self.instance, LCB_ASYNCHRONOUS)

        # set callback handlers
        lcb_set_error_callback(self.instance, error_handler)
        lcb_set_store_callback(self.instance, store_handler)
        lcb_set_get_callback(self.instance, get_handler)

        error = lcb_connect(self.instance)
        if error != LCB_SUCCESS:
            if error == LCB_AUTH_ERROR:
                raise AuthenticationError(lcb_strerror(self.instance, error))
            else:
                raise Exception("Failed to connect: " + \
                                    lcb_strerror(self.instance, error))

    def __dealloc__(self):
        if self.instance:
            lcb_destroy(self.instance)

    @property
    def host(self):
        return lcb_get_host(self.instance)

    @property
    def port(self):
        return lcb_get_port(self.instance)

    def set(self, object key_obj, object value_obj, object callback):
        cdef lcb_error_t error
        cdef lcb_store_cmd_t cmd
        cdef lcb_store_cmd_t *commands[1]

        cdef char *key
        cdef Py_ssize_t nkey
        cdef char *value
        cdef Py_ssize_t nvalue

        PyString_AsStringAndSize(key_obj, &key, &nkey)
        PyString_AsStringAndSize(value_obj, &value, &nvalue)

        commands[0] = &cmd
        memset(&cmd, 0, sizeof(cmd))

        cmd.v.v0.operation = LCB_SET
        cmd.v.v0.key = key
        cmd.v.v0.nkey = nkey
        cmd.v.v0.bytes = value
        cmd.v.v0.nbytes = nvalue

        error = lcb_store(self.instance, <void*>callback, 1, commands)
        if error != LCB_SUCCESS:
            raise Exception(lcb_strerror(self.instance, error))
        print "Store called!"

    def get(self, object key_obj, object callback):
        cdef lcb_error_t error
        cdef lcb_get_cmd_t cmd
        cdef lcb_get_cmd_t *commands[1]

        cdef char *key
        cdef Py_ssize_t nkey

        PyString_AsStringAndSize(key_obj, &key, &nkey)

        commands[0] = &cmd
        memset(&cmd, 0, sizeof(cmd))

        cmd.v.v0.key = key
        cmd.v.v0.nkey = nkey

        error = lcb_get(self.instance, <void*>callback, 1, commands)
        if error != LCB_SUCCESS:
            raise Exception(lcb_strerror(self.instance, error))

