# Roadmap 

## V1 

Profil page:
- classement?
- History (delete?)

Game: 
- Complete Quizz file (fr_app_content,en_app_content,es_app_content)(test)
- Sound when good response is check 

App:
- When language is selected, translate all texte in interface (l18n app)
- Account must be save in local app

Data:
- Verify structure for app_content file
- Create parser content CLI dart -> for test all construction content file and detect error before prod

BUG:
- 

## V2

Onboearding
- Improve speed account setup 

Payment:
- By default pub each 10 question
- Pay 2euros per month for not have pub

## Deploy

- Create new branch in database (branch production)
- Create account for play store and deploy
- Find 15 user for test this app

## Define the objective

The objective of this application is to create an Android and iOS general knowledge app that is enjoyable to use, supports multiple languages, and is fast with a wide variety of questions.

## Storage (Supabase)

The questions/Answers/Score are saved locally (???)
The login and the saving of scores are stored on Supabase

## Data file Example

fr_app_content: 

id:question:rep1:rep2:rep3:rep4:goodresponse:category:note:difficulty
1: "les borders collie sont généralement:":"noir et blanc":"noir et feu":"feu et bleu":"feu":rep1:general:"les borders collies sont généralement noir et blanc !":1 
