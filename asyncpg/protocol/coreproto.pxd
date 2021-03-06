# Copyright (C) 2016-present the ayncpg authors and contributors
# <see AUTHORS file>
#
# This module is part of asyncpg and is released under
# the Apache 2.0 License: http://www.apache.org/licenses/LICENSE-2.0


cdef enum ConnectionStatus:
    CONNECTION_OK = 1
    CONNECTION_BAD = 2
    CONNECTION_STARTED = 3           # Waiting for connection to be made.


cdef enum ProtocolState:
    PROTOCOL_IDLE = 0

    PROTOCOL_FAILED = 1

    PROTOCOL_ERROR_CONSUME = 2

    PROTOCOL_AUTH = 10
    PROTOCOL_PREPARE = 11
    PROTOCOL_BIND_EXECUTE = 12
    PROTOCOL_CLOSE_STMT_PORTAL = 13
    PROTOCOL_SIMPLE_QUERY = 14
    PROTOCOL_EXECUTE = 15
    PROTOCOL_BIND = 16


cdef enum AuthenticationMessage:
    AUTH_SUCCESSFUL = 0
    AUTH_REQUIRED_KERBEROS = 2
    AUTH_REQUIRED_PASSWORD = 3
    AUTH_REQUIRED_PASSWORDMD5 = 5
    AUTH_REQUIRED_SCMCRED = 6
    AUTH_REQUIRED_GSS = 7
    AUTH_REQUIRED_GSS_CONTINUE = 8
    AUTH_REQUIRED_SSPI = 9


AUTH_METHOD_NAME = {
    AUTH_REQUIRED_KERBEROS: 'kerberosv5',
    AUTH_REQUIRED_PASSWORD: 'password',
    AUTH_REQUIRED_PASSWORDMD5: 'md5',
    AUTH_REQUIRED_GSS: 'gss',
    AUTH_REQUIRED_SSPI: 'sspi',
}


cdef enum ResultType:
    RESULT_OK = 1
    RESULT_FAILED = 2


cdef enum TransactionStatus:
    PQTRANS_IDLE = 0                 # connection idle
    PQTRANS_ACTIVE = 1               # command in progress
    PQTRANS_INTRANS = 2              # idle, within transaction block
    PQTRANS_INERROR = 3              # idle, within failed transaction
    PQTRANS_UNKNOWN = 4              # cannot determine status


ctypedef object (*decode_row_method)(object, const char*, int32_t)


cdef class CoreProtocol:
    cdef:
        ReadBuffer buffer
        bint _skip_discard

        ConnectionStatus con_status
        ProtocolState state
        TransactionStatus xact_status

        str encoding

        object transport

        # Dict with all connection arguments
        dict con_args

        readonly int32_t backend_pid
        readonly int32_t backend_secret

        ## Result
        ResultType result_type
        object result
        bytes result_param_desc
        bytes result_row_desc
        bytes result_status_msg

        # True - completed, False - suspended
        bint result_execute_completed

    cdef _process__auth(self, char mtype)
    cdef _process__prepare(self, char mtype)
    cdef _process__bind_execute(self, char mtype)
    cdef _process__close_stmt_portal(self, char mtype)
    cdef _process__simple_query(self, char mtype)
    cdef _process__bind(self, char mtype)

    cdef _parse_msg_authentication(self)
    cdef _parse_msg_parameter_status(self)
    cdef _parse_msg_backend_key_data(self)
    cdef _parse_msg_ready_for_query(self)
    cdef _parse_data_msgs(self)
    cdef _parse_msg_error_response(self, is_error)
    cdef _parse_msg_command_complete(self)

    cdef _auth_password_message_cleartext(self)
    cdef _auth_password_message_md5(self, bytes salt)

    cdef _write(self, buf)
    cdef inline _write_sync_message(self)

    cdef _read_server_messages(self)

    cdef _push_result(self)
    cdef _reset_result(self)
    cdef _set_state(self, ProtocolState new_state)

    cdef _ensure_connected(self)

    cdef WriteBuffer _build_bind_message(self, str portal_name,
                                         str stmt_name,
                                         WriteBuffer bind_data)


    cdef _connect(self)
    cdef _prepare(self, str stmt_name, str query)
    cdef _bind_execute(self, str portal_name, str stmt_name,
                       WriteBuffer bind_data, int32_t limit)
    cdef _bind(self, str portal_name, str stmt_name,
               WriteBuffer bind_data)
    cdef _execute(self, str portal_name, int32_t limit)
    cdef _close(self, str name, bint is_portal)
    cdef _simple_query(self, str query)
    cdef _terminate(self)

    cdef _decode_row(self, const char* buf, int32_t buf_len)

    cdef _on_result(self)
    cdef _set_server_parameter(self, name, val)
    cdef _on_connection_lost(self, exc)
