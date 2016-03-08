# Uncomment below lines if you don't have the forecast and e1071 packages installed
#install.packages('forecast',repos="http://cran.us.r-project.org")
#install.packages('e1071',repos="http://cran.us.r-project.org")

library(forecast)
library(e1071)

# Please put the data file training and validation in an folder named input
# under your working director
# You can get your current working directory by getwd()

cat("reading the train and validation data\n")
train <- read.table("./input/training")
validation  <- read.table("./input/validation")

# Define error metrics
RMSPE <- function(val, pred){
  err <- sqrt(mean((pred/val-1)^2))
  return(err)
}

RMSE <- function(val,pred){
  err <- sqrt(mean((pred-val)^2))
  return(err)
}

# Functions to compute forecasts

seasonal.naive <- function(train){
  # Computes seasonal naive forecast
  #
  # Set each forecast to be equal to the value of the same weekday 
  # of the last observed 7 days
  
  horizon <- 30  # period to forecast
  fc <- train[rep_len(nrow(train) - (7:1) + 1,horizon),]
  fc[is.na(fc)] <- 0 # if the observation is NA, forecast 0
  
  return(fc) 
}

# Compare forecast with validation set
s1 <- ts(validation)
s2 <- ts(seasonal.naive(train))
ts.plot(s1,s2,col=c('red','blue'),lwd=2,ylim=c(4e7,8e7),
        xlab='Day',ylab='Ad Impressions',
        main='Forecast by Seaonal Naive Model')
legend(25,7.8e7,c("forecast","validation"),lty=c(1,1),lwd=c(2.5,2.5),col=c('blue','red'))

RMSPE(validation,seasonal.naive(train))
RMSE(validation,seasonal.naive(train))

tslm.basic <- function(train,degree=1){
  # Computes a forecast using linear regression and seasonal dummy variables
  #
  horizon <- 30
  l <- nrow(train) + horizon
  
  # Assume the first data point in train set is day 1, generate new variable weekday
  data <- data.frame(adi=c(train[,1],rep(0,30)),trend=c(1:l),weekday=rep_len((1:7),l))
  
  # Generate dummy variables based on weekday
  # day_i = 1 if the weekday is i else 0
  for (i in 1:6){
    data[paste('day',i,sep='')] <- ifelse(data$weekday==i,1,0)  
  }
  
  # split the train and validation set
  train <- data[1:nrow(train),]
  val <- data[(nrow(train)+1):l,]
  
  if (degree==1){
    model <- lm(adi~.-weekday,data=train)
  } else{
    model <- lm(adi~.-weekday-trend+I(trend^degree),data=train)
  }
  
  fc <- predict(model,val)
  
  return(fc)
}

tslm.svm <- function(train){
  horizon <- 30
  l <- nrow(train) + horizon
  data <- data.frame(adi=c(train[,1],rep(0,30)),trend=c(1:l),weekday=rep_len((1:7),l))
  for (i in 1:6){
    data[paste('day',i,sep='')] <- ifelse(data$weekday==i,1,0)  
  }
  train <- data[1:nrow(train),]
  val <- data[(nrow(train)+1):l,]
  
  model <- svm(adi~.,
               data=train,
               cost=3,
               gamma=0.05,
               epsilon=0.0001
               )
  
  fc <- predict(model,val)
  
  return(fc)
  
}

stl <- function(train,method='ets'){
  # Computes the forest using stlf() from the forecast package.
  # using an exponential smoothing model (ets) or arima for the non-seasonal forecast.
  
  horizon <- 30
  
  # Convert the list of values to time series object, frequency set to 7 to 
  # reflect weekly pattern
  s <- ts(train[, 1],frequency=7)
  
  if (method=='ets'){
    # stlf() functions gives forecast on the given time series and horizon
    fc <- stlf(s, 
               h=horizon, 
               s.window="periodic",
               method='ets',
               ic='bic',
               robust=TRUE)
  } else if(method=='arima'){
    fc <- stlf(s, 
               h=horizon, 
               s.window="periodic",
               method='arima',
               ic='bic',
               robust=TRUE)
  }
  
  return(as.numeric(fc$mean))
}

seasonal.arima <- function(train){
  horizon <- 30
  s <- ts(train[, 1],frequency=7)
  model <- auto.arima(s, 
                      ic='bic', 
                      seasonal.test='ch',
                      seasonal=TRUE)
  fc <- forecast(model, h=horizon)
  
  return(as.numeric(fc$mean))
}

ensemble.forecast <- function(train){
  # Computes the first ensemble: ensemble of two tslm models
  tslm.avg <- (tslm.basic(train,2)+tslm.basic(train,3))/2
  
  # The final ensemble: a unweighted average of the three models
  fc <- (tslm.avg + tslm.svm(train) + seasonal.arima(train))/3
  
  return(fc)
}

RMSPE(validation,ensemble.forecast(train))
RMSE(validation,ensemble.forecast(train))
  
