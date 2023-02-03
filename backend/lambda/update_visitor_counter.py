import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
target_database = os.environ['DATABASE_NAME']
domain_name = os.environ['DOMAIN_NAME']

def lambda_handler(event, context):

    table = dynamodb.Table(target_database)
    

    res = table.update_item(
        Key={
            'PK': 'data',
            'SK': 'visitor_count'
        },
        UpdateExpression="SET db_value = if_not_exists(db_value, :start) + :inc",
        ExpressionAttributeValues={
            ':inc': 1,
            ':start': 0,
        },
        ReturnValues="UPDATED_NEW"
        )
    visitor_count = str(res['Attributes']['db_value'])

    return {
        'statusCode': 200,
        'body': visitor_count,
        'headers': {
            'Access-Control-Allow-Origin': f'https://{domain_name}',
        }
    }
