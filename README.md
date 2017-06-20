# kanjiryokucha
An iOS front end for kanji.koohii.com (SRS kanji reviews)

Kanji Koohii is a web-based flashcard system for studying the meanings of kanji characters, or rather, keywords that are associated to them. The site uses the Spaced Repetition System to choose which cards you are presented with each day.

Kanji Ryokucha is a native iOS front end to Kanji Koohii in which you don't just get the native feel when reviewing, you can also draw the kanji for the presented keyword and then compare that to the correct kanji. Additionally you can check out an animation showing the stroke order for the kanji (when available), see kanji readings, and refer back to the study page for the kanji in Kanji Koohii.

Kanji Ryokucha also includes a Study phase (enabled by default) where you can relearn failed kanji, and a free non-SRS review feature.

## Technical

*Note: service API keys are not included as part of the public repo. You need to get those in order to be able to build the project. You should see a missing ApiKey.swift file that should go in the main 'kanjiryokucha' folder.*

The project is written in Swift and uses Cocoapods for dependencies.

Major features are coded with functional reactive style (using ReactiveSwift). 

Realm is used for the local DB. 

Gloss is used to parse JSON.

Stroke order animations from Kanji Alive's public API.
