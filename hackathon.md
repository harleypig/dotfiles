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
