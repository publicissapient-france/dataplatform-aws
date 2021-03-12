import os
import logging
from pythonjsonlogger import jsonlogger


# Remove all setup done by aws
root_logger = logging.getLogger()
for h in root_logger.handlers:
    root_logger.removeHandler(h)


class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def __init__(self, *args, **kwargs):
        super(CustomJsonFormatter, self).__init__(*args, **kwargs)
        self.correlation_id = None
        self.request_id = None
        self.source = None
        self.module = None
        self.component = None
        self.environment = None

    def set_correlation_id(self, correlation_id):
        self.correlation_id = correlation_id

    def set_request_id(self, request_id):
        self.request_id = request_id

    def set_source(self, source):
        self.source = source

    def set_environment(self, environment):
        self.environment = environment

    def set_module(self, module):
        self.module = module

    def set_component(self, component):
        self.component = component

    def add_fields(self, log_record, record, message_dict):
        super(CustomJsonFormatter, self).add_fields(log_record, record, message_dict)

        log_record['timestamp'] = log_record['asctime']
        log_record['file'] = "{}.{}#{}".format(log_record['filename'], log_record['funcName'], log_record['lineno'])
        log_record['correlation_id'] = self.correlation_id
        log_record['request_id'] = self.request_id
        log_record['sourcename'] = self.source
        log_record['module'] = self.module
        log_record['component'] = self.component
        log_record['environment'] = self.environment
        log_record['level'] = log_record['levelname']

        # Remove unnecessaries keys
        log_record.pop('levelname')
        log_record.pop('lineno')
        log_record.pop('asctime')


formatter_json = CustomJsonFormatter('%(name)s %(asctime)s %(levelname)s %(filename)s %(funcName)s %(lineno)s %(message)s %(file)s')


def set_correlation_id(correlation_id):
    formatter_json.set_correlation_id(correlation_id)


def set_request_id(request_id):
    formatter_json.set_request_id(request_id)


def set_source(source):
    formatter_json.set_source(source)


def set_environment(environment):
    formatter_json.set_environment(environment)


def set_module(module):
    formatter_json.set_module(module)


def set_component(component):
    formatter_json.set_component(component)


# autoconfigure logger
set_module(os.environ.get('MODULE'))
set_component(os.environ.get('COMPONENT'))
set_environment(os.environ.get('ENVIRONMENT'))


def get_logger(logger_name: str = 'fr.publicissapient'):
    logger = logging.getLogger(logger_name)
    logger.setLevel(os.environ.get("LOGGER_LEVEL", "DEBUG"))

    # Remove all setup done by aws
    for h in logger.handlers:
        logger.removeHandler(h)

    if os.getenv("LOG_TYPE", "TEXT") == "JSON":
        handler_json = logging.StreamHandler()
        handler_json.setFormatter(formatter_json)
        logger.addHandler(handler_json)
    else:
        handler_string = logging.StreamHandler()
        handler_string.setFormatter(
            logging.Formatter('[%(asctime)s | %(levelname)5s | %(filename)s.%(funcName)s#%(lineno)d] %(message)s'))
        logger.addHandler(handler_string)

    return logger
