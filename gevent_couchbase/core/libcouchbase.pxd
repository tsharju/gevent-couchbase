cdef extern from "stdint.h":
    ctypedef unsigned int uint16_t
    ctypedef unsigned long int uint32_t
    ctypedef unsigned long long int uint64_t

cdef extern from "libcouchbase/couchbase.h":

    ctypedef void * lcb_t
    ctypedef size_t lcb_size_t
    ctypedef uint64_t lcb_cas_t

    ctypedef enum lcb_error_t:
        LCB_SUCCESS
        LCB_AUTH_CONTINUE
        LCB_AUTH_ERROR
        LCB_DELTA_BADVAL
        LCB_E2BIG
        LCB_EBUSY
        LCB_EINTERNAL
        LCB_EINVAL
        LCB_ENOMEM
        LCB_ERANGE
        LCB_ERROR
        LCB_ETMPFAIL
        LCB_KEY_EEXISTS
        LCB_KEY_ENOENT
        LCB_DLOPEN_FAILED
        LCB_DLSYM_FAILED
        LCB_NETWORK_ERROR
        LCB_NOT_MY_VBUCKET
        LCB_NOT_STORED
        LCB_NOT_SUPPORTED
        LCB_UNKNOWN_COMMAND
        LCB_UNKNOWN_HOST
        LCB_PROTOCOL_ERROR
        LCB_ETIMEDOUT
        LCB_CONNECT_ERROR
        LCB_BUCKET_ENOENT
        LCB_CLIENT_ENOMEM
        LCB_CLIENT_ETMPFAIL
        LCB_EBADHANDLE
        LCB_SERVER_BUG
        LCB_PLUGIN_VERSION_MISMATCH

    ctypedef enum lcb_storage_t:
        LCB_ADD
        LCB_REPLASE
        LCB_SET
        LCB_APPEND
        LCB_PREPEND
        
    ctypedef enum lcb_syncmode_t:
        LCB_ASYNCHRONOUS
        LCB_SYNCHRONOUS

    ctypedef enum lcb_type_t:
        LCB_TYPE_BUCKET
        LCB_TYPE_CLUSTER

    cdef struct lcb_create_st_v0:
        char *host
        char *user
        char *passwd
        char *bucket
        lcb_io_opt_st *io

    cdef struct lcb_create_st_v1:
        char *host
        char *user
        char *passwd
        char *bucket
        lcb_type_t type

    cdef union lcb_create_st_union:
        lcb_create_st_v0 v0
        lcb_create_st_v1 v1

    cdef struct lcb_create_st:
        int version
        lcb_create_st_union v

    ctypedef enum lcb_io_ops_type_t:
        LCB_IO_OPS_DEFAULT
        LCB_IO_OPS_LIBEVENT
        LCB_IO_OPS_WINSOCK
        LCB_IO_OPS_LIBEV

    cdef struct lcb_create_io_ops_st_v0:
        lcb_io_ops_type_t type
        void *cookie

    cdef struct lcb_create_io_ops_st_v1:
        char *sofile
        char *symbol
        void *cookie

    cdef union lcb_create_io_ops_st_union:
        lcb_create_io_ops_st_v0 v0
        lcb_create_io_ops_st_v1 v1

    cdef struct lcb_create_io_ops_st:
        int version
        lcb_create_io_ops_st_union v

    cdef struct lcb_io_opt_st:
        pass

    ctypedef lcb_io_opt_st *lcb_io_opt_t

    char *lcb_get_host(lcb_t instance)
    char *lcb_get_port(lcb_t instance)

    lcb_error_t lcb_create(lcb_t *instance, lcb_create_st *options)
    lcb_error_t lcb_create_io_ops(lcb_io_opt_t *op, lcb_create_io_ops_st *options)

    lcb_error_t lcb_wait(lcb_t instance)
    void lcb_destroy(lcb_t instance)

    char *lcb_strerror(lcb_t instance, lcb_error_t error)

    void lcb_behavior_set_syncmode(lcb_t instance, lcb_syncmode_t syncmode)
    lcb_syncmode_t lcb_behavior_get_syncmode(lcb_t *instance)

    lcb_error_t lcb_connect(lcb_t instance)

    # callbacks
    ctypedef void (*lcb_error_callback)(lcb_t instance,
                                        lcb_error_t error,
                                        char *errinfo)
    lcb_error_callback lcb_set_error_callback(lcb_t, lcb_error_callback)

    # store
    cdef struct lcb_store_cmd_t_v0:
        lcb_storage_t operation
        void *key
        lcb_size_t nkey
        void *bytes
        lcb_size_t nbytes

    cdef union lcb_store_cmd_t_union:
        lcb_store_cmd_t_v0 v0

    cdef struct lcb_store_cmd_st:
        int version
        lcb_store_cmd_t_union v

    ctypedef lcb_store_cmd_st lcb_store_cmd_t

    ctypedef struct lcb_store_resp_t_v0:
        void *key
        lcb_size_t nkey
        lcb_cas_t cas

    ctypedef union lcb_store_resp_t_union:
        lcb_store_resp_t_v0 v0

    ctypedef struct lcb_store_resp_t:
        int version
        lcb_store_resp_t_union v

    lcb_error_t lcb_store(lcb_t instance,
                          void* command_cookie,
                          lcb_size_t num,
                          lcb_store_cmd_t **commands)

    ctypedef void (*lcb_store_callback)(lcb_t instance,
                                        void *cookie,
                                        lcb_storage_t operation,
                                        lcb_error_t error,
                                        lcb_store_resp_t *resp)

    lcb_store_callback lcb_set_store_callback(lcb_t, lcb_store_callback)

    # get
    cdef struct lcb_get_cmd_st_v0:
        void *key
        lcb_size_t nkey

    cdef union lcb_get_cmd_st_union:
        lcb_get_cmd_st_v0 v0

    cdef struct lcb_get_cmd_st:
        int version
        lcb_get_cmd_st_union v

    ctypedef lcb_get_cmd_st lcb_get_cmd_t

    ctypedef struct lcb_get_resp_t_v0:
        void *key
        lcb_size_t nkey
        void *bytes
        lcb_size_t nbytes

    ctypedef union lcb_get_resp_t_union:
        lcb_get_resp_t_v0 v0

    ctypedef struct lcb_get_resp_t:
        int version
        lcb_get_resp_t_union v

    lcb_error_t lcb_get(lcb_t instance,
                        void *command_cookie,
                        lcb_size_t num,
                        lcb_get_cmd_t **commands)

    ctypedef void (*lcb_get_callback)(lcb_t instance,
                                      void *cookie,
                                      lcb_error_t error,
                                      lcb_get_resp_t *resp)
    lcb_get_callback lcb_set_get_callback(lcb_t, lcb_get_callback)
