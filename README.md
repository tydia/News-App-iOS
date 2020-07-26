# News App

## What is this app?
This app is a news app. You can not only read most recent top news, but also can read top news in different topics. If you like a specific news and want to read them later, you can simply add bookmarks, and you'll be able to delete them if they already read it. Want to search something? No problem. Just type in the keyword in your mind in the search bar. Autocomplete is also provided for your convenience. Last but not least, you can also search for the trend of some news in recent 90 days.

## Demo  
[![](http://img.youtube.com/vi/DflbOsZf9cc/0.jpg)](http://www.youtube.com/watch?v=DflbOsZf9cc "News APP")

## Technical Details
This app is a mixture of iOS development and web technologies. It is developed under Xcode 11, Swift 5.3.
For pods used, you can go to the `Pods` directory to have an idea. In addition to that, here is a list of APIs used in this project:
- [Open Weather API](https://openweathermap.org/api)
- [Guardian's News API](https://open-platform.theguardian.com)
- [Bing Autosuggest API](https://azure.microsoft.com/en-us/services/cognitive-services/autosuggest/)
- [Google Trends API](https://trends.google.com/trends/?geo=US)
A Node.js backend was developed and deployed on AWS for fetching contents. See `news_app_ios_backend` folder for backend code.

## Important note: 
The backend is currently not deployed since AWS is too expensive. So the app will not function properly if you compile it. I'll deploy the backend to GCP in future.
