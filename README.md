# Ad-Impression-Forecast

This is a project I did for online in-image ad vendor GumGum. GumGum aims to forecast ad impression numbers on GumGum’s affiliated websites in the next 30 days based on the past 365 days data.

The final forecast model is an ensemble of five simple models:

- Seasonal naive model
- Linear regression model with trend and seasonal dummy variables (day of week)
- SVM regression with trend and seasonal dummy variables (day of week)
- STL + ETS/Arima model
- Arima model

Here's the link to my code and visulization:
[ad-impression-forecast-web-view](http://htmlpreview.github.io/?https://raw.githubusercontent.com/bozhang0504/Ad-Impression-Forecast/master/Ad_Impression_Forecast.html)

