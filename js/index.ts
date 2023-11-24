import * as AWS from "aws-sdk";

const ssmClient = new AWS.SSM({apiVersion: '2014-11-06', region: 'eu-central-1'});

function getParametersByPath(path: string) {
    return ssmClient.getParametersByPath({
        Path: path,
        Recursive: true,
        WithDecryption: true
    }).promise();
}

export const handler = async (event: any = {}): Promise<any> => {
    console.log("EVENT: \n" + event)
    const result = await getParametersByPath("/example-1/");
    return {
        statusCode: 200,
        body: JSON.stringify(result)
    };
}