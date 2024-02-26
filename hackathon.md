# Chatbot with Vertex Model

## AIDER

Do not modify this section.

### Constraints

This document will be shared with both volunteers for the hackathon team will
need an idea of what needs to be done and to management who don't need a lot
of detail.

No company data or code can be used in the sandbox environment, so we'll need
to use an open source project--preferably one that we currently use--as an
example for the RAG data. Once we've moved to the production environment
(where dev, test and stage environments will live) we can add necessary code
and documentation into a separate RAG model.

### What is needed?

I need to create a document with two sections. The first section should give an
overview of what needs to be done in creating a RAG based Vertex AI model,
with some possible ways it could be done.

The second section should be an overview of how to create a teams chatbot that
uses the RAG model created in the previous section. We need to include the
steps to prepare (how do we connect a bot to teams?) and we need to highlight
the idea that a bot would listen on a single, or if needed, multiple defined
channels. This bot would not be listening to all of our company teams
channels.

## Creating a RAG-based Vertex AI Model

* Select an open-source project that aligns with our technology stack to use as a foundation.
* Curate and sanitize datasets for training the model.
* Construct the model architecture with:
  * A retriever component to fetch relevant information.
  * A generator component to produce the output.
* Train the model iteratively and evaluate to fine-tune performance.
* Document the process after successful sandbox testing.
* Prepare for migration to the production environment to incorporate company-specific data and code.

### For Hackathon

* Identify a simple use case for the RAG model within the scope of the hackathon.
* Set up a basic Vertex AI environment for model development.
* Select a small, relevant dataset for the proof-of-concept.
* Develop a basic RAG model structure with placeholder components.
* Implement a simple retriever and generator for initial testing.
* Train the proof-of-concept model with the selected dataset.
* Evaluate the model's performance and refine as necessary.
* Create a basic interface for model interaction to demonstrate its capabilities.
