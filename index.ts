import { APIGatewayEvent, Handler } from 'aws-lambda';
import { S3Client, PutObjectCommand, HeadObjectCommand, NotFound } from '@aws-sdk/client-s3';
import { nanoid } from 'nanoid';
import { z } from 'zod';

const { region, logLevel, bucketName, staticEndpoint } = process.env;

const LogLevel = {
  Debug: 'Debug',
  Info: 'Info',
  Warn: 'Warn',
  Error: 'Error',
} as const;
type LogLevel = keyof typeof LogLevel;
const logLevelvalue = LogLevel[(logLevel as keyof typeof LogLevel) ?? 'Error'];

const HttpStatusCode = {
  OK: 200,
  NOT_FOUND: 404,
  INTERNAL_SERVER_ERROR: 500,
} as const;
type HttpStatusCodeType = (typeof HttpStatusCode)[keyof typeof HttpStatusCode];

type ReturnType = {
  statusCode: number;
  headers: { [key: string]: string };
  body: string;
  isBase64Encoded: boolean;
};

const s3Client = new S3Client({ region: region });

const bodySchema = z.object({
  url: z.string().url(),
});

export const handler: Handler<APIGatewayEvent, ReturnType> = async (event): Promise<ReturnType> => {
  logMessage('\nReading options from event with body:\n' + JSON.stringify(event.body), LogLevel.Info);

  // Make sur env variables are there
  if (!bucketName || !staticEndpoint) {
    logMessage('Missing environments variables', LogLevel.Error);
    return getReturnObjectForError(HttpStatusCode.NOT_FOUND, 'Unexpected error');
  }

  // Validate the body
  let url: string;
  try {
    const body: unknown = JSON.parse(event.body as string);
    const parsedBody = await bodySchema.parseAsync(body);
    url = parsedBody.url;
  } catch (error) {
    if (error instanceof Error) {
      logMessage(error.message, LogLevel.Error);
    }
    return getReturnObjectForError(HttpStatusCode.NOT_FOUND, 'Invalid body, missing or invalid url');
  }

  // Make sure the key is not already used
  let key = '';
  let isKeyUsed = true;

  try {
    while (isKeyUsed) {
      key = nanoid(6);
      isKeyUsed = await doesKeyExist(key);
    }
  } catch (error) {
    if (error instanceof Error) {
      logMessage(error.message, LogLevel.Error);
    }
    return getReturnObjectForError(HttpStatusCode.INTERNAL_SERVER_ERROR, 'Unexpected error');
  }

  try {
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: key,
      WebsiteRedirectLocation: url,
    });
    await s3Client.send(command);
  } catch (error) {
    if (error instanceof Error) {
      logMessage(error.message, LogLevel.Error);
    }
    return getReturnObjectForError(HttpStatusCode.INTERNAL_SERVER_ERROR, 'Unexpected error');
  }

  return getReturnObject(HttpStatusCode.OK, {
    url: `${staticEndpoint}/${key}`,
  });
};

const doesKeyExist = async (key: string) => {
  try {
    const command = new HeadObjectCommand({
      Bucket: bucketName,
      Key: key,
    });
    await s3Client.send(command);
    return true;
  } catch (error) {
    if (error instanceof NotFound) {
      return false;
    } else {
      throw error;
    }
  }
};

const getReturnObjectForError = (statusCode: HttpStatusCodeType, message: string): ReturnType => {
  return getReturnObject(statusCode, { error: message });
};

const getReturnObject = (statusCode: HttpStatusCodeType, body: object): ReturnType => {
  return {
    statusCode: statusCode,
    headers: {
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': '*',
    },
    body: JSON.stringify(body),
    isBase64Encoded: false,
  };
};

const logMessage = (message: string, level: LogLevel) => {
  if (level >= logLevelvalue) {
    switch (level) {
      case LogLevel.Debug:
        console.debug(message);
        break;
      case LogLevel.Info:
        console.log(message);
        break;
      case LogLevel.Warn:
        console.warn(message);
        break;
      case LogLevel.Error:
        console.error(message);
        break;
    }
  }
};
