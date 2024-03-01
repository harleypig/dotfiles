# Chatbot with Vertex Model

## AIDER

Do not modify this section.

This is a chat transcript. I need to format my questions, the other persons
answers and respond to the other persons answers in a business type format.
This will be placed in a confluence page.

I need to describe, briefly, how we can setup programmatic access to microsoft
teams, and how we can secure it within our network and how a chatbot would
work with an ai to provide support to a teams channel.

Put the documentation in the '## Writeup' section.

### Transcript

Me: Mark, do you what the concerns are with having programmatic access to
teams?

Mark: Can you put some context around this?

Me: I asked about creating a RAG Vertex AI in hackathon with a view to
creating a chatbot to answer questions about using <internal library>. I was
told accessing teams via programs was not allowed.

Mark: from who? I am quite curious who the source of that was

Me: <co-workder>

Mark: In sandbox you can't, but I have never heard that before.

Me: I'm guessing he was told that, he wants to have something similar.
  Oh, that's probably what he meant ... we'd have to use Vertex from sandbox
  for the hackathon.

Mark: Crossing the stream between sbox and prod

Me: But for development I presume we'd be using the dev environment in the
prod cloud.

Mark: If that is the case, it is more accepting. Where it goes sideways is
"access to production data"

Me: That would be a different RAG Vertex AI I would guess. Ideally, and
ultimately, we'd have a RAG Vertex AI for chat and copilot, and that wouldn't
need prod data.

Mark: Now if we are able to limit it to a specific channel in teams, my pitch
to leadership would be that it is a lot easier for us to watch one channel
than all of teams

Me: Oh,  yeah. I wasn't thinking of something would spam teams. :D It would
just sit on something like <support chat> and respond to questions there.
Possibly even only to specific prompts, like 'Hey bot! ...'

Mark: I think put a fence around it can take some of the boogeyman fear out of
it.

Me: But for this hackathon, I just want to demonstrate how we could use RAG
for focusing an AI to our specific needs, and limit it to the <internal
library>.
  I'm ok with not being to cross from sandbox to teams ... I didn't think
  about that part of it when I asked.

Mark: Can you do a write up of it, with the fencing around it, and I will take
to Rick and Jami. I'll see what we have on the Symantec or Msft side to see if
we can wrap a bit more around it.

## Writeup

Programmatic Access to Microsoft Teams:

To set up programmatic access to Microsoft Teams, we can utilize the Microsoft
Graph API, which provides a unified programmability model that you can use to
access the tremendous amount of data in Microsoft 365, Windows 10, and
Enterprise Mobility + Security. The access can be secured by implementing
OAuth 2.0 authorization and by restricting the permissions to the minimum
required for the chatbot's functionality.

Securing the Access within Our Network:

The access to Microsoft Teams can be secured by:
* Using secure tokens for authentication.
* Implementing IP whitelisting to allow access only from our network.
* Applying the principle of least privilege by granting the chatbot only the
   permissions it needs to function.
* Regularly reviewing and auditing the access logs.

Chatbot Interaction with AI:

The chatbot can be integrated with an AI model hosted on Vertex AI to provide
support within a Teams channel. The AI model can be trained on specific
datasets relevant to our internal library to ensure that the responses are
accurate and contextually relevant. The chatbot can be programmed to respond
to specific prompts or commands, reducing the risk of it spamming the channel.

For the hackathon, the focus will be on demonstrating the use of Vertex AI to
tailor the AI model to our specific needs, such as providing support for the
internal library. The development and testing will be done in a sandbox
environment, with no access to production data. The goal is to showcase
a proof of concept that can be further developed and potentially integrated
into a production environment with the appropriate safeguards in place.

The chatbot will be designed to operate within a specific Teams channel, which
will make it easier to monitor and manage. By limiting the chatbot's scope, we
can mitigate concerns regarding security and data privacy.

This document will serve as a preliminary write-up to present to leadership
for review and consideration. Further technical details and a comprehensive
security strategy will be developed following initial approval.
