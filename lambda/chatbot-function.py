import json
import boto3
import botocore

# Initialize clients
s3 = boto3.client('s3')
bedrock = boto3.client(service_name='bedrock-runtime', region_name='us-east-1',
                       config=botocore.config.Config(read_timeout=600, retries={'max_attempts': 3}))

# Bucket name and object key
BUCKET_NAME = "adi-cloud-resume-challenge-bucket"
OBJECT_KEY = "Aditya Krishnakumar Resume textfile.txt"


def lambda_handler(event, context):
    # 1. Parse user question from API Gateway event
    body = json.loads(event.get('body', '{}'))
    user_question = body.get('prompt', 'Who is this person?')

    # 2. Fetch Resume Text from S3 (Free Tier)
    # Cache this inside the lambda outside the handler if you want to save S3 calls on warm starts
    resume_object = s3.get_object(Bucket=BUCKET_NAME, Key=OBJECT_KEY)
    resume_text = resume_object['Body'].read().decode('utf-8')

    # 3. Construct the Prompt (Context Stuffing)
    # We tell the AI strictly how to behave.
    prompt_data = f"""
    You are Aditya Krishnakumar, a results-driven Software Developer. 
    Your persona must be smart, confident, and highly professional.
    Do not refer to yourself in the third person. 
    You communicate clearly, focusing on achievements and technical expertise. 
    You are not afraid to highlight your skills and experience to show value. 
    When answering, structure the information logically and always sound prepared and knowledgeable, whilst keeping the answers precise to the question without overfilling the answer.

    You have access to the complete, structured resume of Aditya Krishnakumar. 
    Your sole function is to act as a chatbot assistant, answering questions about Aditya Krishnakumar as himself, using only the information provided in the text file below. 
    Do not invent any information. 
    If the information is not present, state confidently that the specific detail is not documented on the resume, but pivot to a related, documented strength.

    RESUME CONTEXT:
    {resume_text}

    USER QUESTION:
    {user_question}
    """

    # 4. Call Bedrock (Claude 3 Haiku is cheapest/fastest)
    # Note: Payload structure depends on the model. This is for Claude 3.
    payload = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 300,
        "temperature": 0.5,
        "top_k": 1,
        "top_p": 0.9,
        "messages": [
            {
                "role": "user",
                "content": [{"type": "text", "text": prompt_data}]
            }
        ]
    }

    response = bedrock.invoke_model(
        modelId="anthropic.claude-3-haiku-20240307-v1:0",
        contentType="application/json",
        accept="application/json",
        body=json.dumps(payload)
    )

    # 5. Parse and Return Response
    response_body = json.loads(response.get('body').read())
    answer = response_body['content'][0]['text']

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',  # Enable CORS
            'Access-Control-Allow-Methods': 'POST'
        },
        'body': json.dumps({'response': answer})
    }
