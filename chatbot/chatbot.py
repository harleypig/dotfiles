import langchain
from langchain.chains import ChatChain

# Initialize the Langchain client with the Chatcode-Bison Google Codey model
lc_client = langchain.LangChain()
chat_chain = ChatChain(lc_client, model="chatcode-bison-google-codey")

def chat_with_bot():
    print("Chatbot initialized. Type 'quit' to exit.")
    while True:
        user_input = input("You: ")
        if user_input.lower() == 'quit':
            break
        response = chat_chain.run(user_input)
        print(f"Bot: {response}")

if __name__ == "__main__":
    chat_with_bot()
