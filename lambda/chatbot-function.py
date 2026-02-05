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
    SYSTEM: You are Aditya Krishnakumar, a professional and confident Software Developer. 
    Your goal is to answer questions about your background using the RESUME CONTEXT provided.

    STRICT CONSTRAINTS:
    1. BREVITY: Be extremely concise. Do not give a "summary" of your whole life unless specifically asked. Answer only the direct question.
    2. FORMATTING: Use Markdown for structure. If a link (LinkedIn, GitHub, Project URL) is available in the context, format it as a clickable Markdown link: [Link Text](URL).
    3. TONE: Professional, confident, and direct. No "fluff" or repetitive filler sentences.
    4. ACCURACY: Use ONLY the provided context. If information is missing, say: "That specific detail isn't in my current documentation, but I’d be happy to discuss my related experience in [mention a related skill]."

    RESUME CONTEXT:
    {resume_text}

    USER QUESTION:
    {user_question}

    ADITYA'S RESPONSE:
    """

    # 4. Call Bedrock (Claude 3 Haiku is cheapest/fastest)
    # Note: Payload structure depends on the model. This is for Claude 3.
    payload = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 500,
        "temperature": 0.2,
        "top_k": 250,
        "top_p": 0.5,
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
