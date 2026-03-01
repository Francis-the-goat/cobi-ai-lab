import pino from 'pino';
import { Logger } from '../types/index.js';

const baseLogger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  base: { service: 'radar-system' },
  transport:
    process.env.NODE_ENV === 'production'
      ? undefined
      : {
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'yyyy-mm-dd HH:MM:ss.l o',
            ignore: 'pid,hostname',
          },
        },
});

export const logger: Logger = {
  info(message, context) {
    if (context) {
      baseLogger.info(context, message);
      return;
    }
    baseLogger.info(message);
  },
  warn(message, context) {
    if (context) {
      baseLogger.warn(context, message);
      return;
    }
    baseLogger.warn(message);
  },
  error(message, context) {
    if (context) {
      baseLogger.error(context, message);
      return;
    }
    baseLogger.error(message);
  },
  debug(message, context) {
    if (context) {
      baseLogger.debug(context, message);
      return;
    }
    baseLogger.debug(message);
  },
};

export default logger;
