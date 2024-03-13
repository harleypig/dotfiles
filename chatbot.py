import vertexai

def chat_with_codechat(prompt, session_params=None, chat_params=None):
    if session_params is None:
        session_params = {}
    if chat_params is None:
        chat_params = {}

    # Create a CodeChatSession with the given parameters
    session = vertexai.CodeChatSession(**session_params)

    # Send the prompt to the CodeChatSession and get the response
    response = session.send(prompt, **chat_params)

    # Return the response as a string
    return response.text

# Example usage:
# response = chat_with_codechat("Hello, how can I help you today?")
# print(response)
