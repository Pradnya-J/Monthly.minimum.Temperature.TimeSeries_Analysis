#Pradnya Jagtap A005 FTSA SC Assignment

######### Different DATA SET ###########

data = read.csv("~/Downloads/archive/daily-minimum-temperatures-in-me.csv")
View(data)
head(data)
# Check the structure of the data
str(data)
# Convert 'Daily.minimum.temperatures' to numeric
data$Date = as.Date(data$Date,'%m/%d/%Y')
data$Daily.minimum.temperatures <- as.numeric(data$Daily.minimum.temperatures)
str(data)
library(zoo)
# Replace NA values with the average of previous and next values
data$Daily.minimum.temperatures <- na.approx(data$Daily.minimum.temperatures)


## checking Na and null values 
na_counts <- sapply(data, function(x) sum(is.na(x)))
na_counts
missing_counts <- sapply(data, function(x) sum(is.na(x) | x == ""))
missing_counts
date_missing <- sum(is.na(data$Date))
# Print the number of NA values in the 'Date' column
print(date_missing)

View(data)
summary(data)

# Create a new column for the year and month
data$YearMonth <- format(data$Date, "%Y-%m")
# Use the aggregate function to calculate the monthly mean of 'Daily.minimum.temperatures'
monthly_data <- aggregate(Daily.minimum.temperatures ~ YearMonth, data, mean)
# Convert the 'YearMonth' column back to Date format if desired
monthly_data$YearMonth <- as.Date(paste0(monthly_data$YearMonth, "-01"))
# Optionally, rename the columns if desired
colnames(monthly_data) <- c("Date", "Monthly.minimum.temperatures")
# Print the first few rows of the monthly data
head(monthly_data)
View(monthly_data)# 120 entries


temp_ts = ts(monthly_data$Monthly.minimum.temperatures, start = c(1981, 1), frequency = 12)
plot(temp_ts) #time series data for 120 obs seasonality present
# seems to be stationary series.
# to check it with test.
summary(temp_ts)
temp_ts_filled <- temp_ts
# Summary of the filled time series
summary(temp_ts_filled) # No NA values now
plot(temp_ts_filled)


##### checking the auto correlation in the series
Box.test(temp_ts_filled, type= 'Ljung-Box')
"reject the null hypothesis and conclude that there is significant autocorrelation 
in the time series beyond the lag specified in the test.So we need to difference the series."


#####  checking ADF and Kpss test for stationarity 
"ADF
H0 : series is non stationary
H1 : series is stationary "

library(tseries)
adf.test(temp_ts_filled)
" p-value = 0.01 < 0.05
So we reject H0. ie.is stationary"

# KPSS test
" H0 : TS is stationary
H1 : TS is not staioanary"
kpss.test(temp_ts_filled)
# p-value = 0.1 > 0.05 so we do not reject H0 i.e. is stationary

acf(temp_ts_filled,50) # NON STATIONARY TIME SERIES

#to make stationary
diff1 = diff(temp_ts_filled) # nonseasonal differencing
plot(diff1)

adf.test(diff1)
" p-value = 0.01 < 0.05
So we reject H0. ie.is stationary"

kpss.test(diff1)
# p-value = 0.1 > 0.05 so  we do not reject H0 i.e. is stationary

# Adjust plot margins
par(mfrow = c(1,1))
# Plot ACF of differenced series
acf(diff1) # 2 spikes so MA(2)
# Plot PACF of differenced series
pacf(diff1)# 6 spikes AR(6)
"indicates a strong autoregressive relationship in the time series data,
with decreasing correlation as the lag increases.
So now,
1st order nonseasonal differencing as d=1, p=6, and q=2
"

# Calculate the number of rows for training and testing
n_rows <- nrow(monthly_data)
n_train <- round(0.8 * n_rows)  # 80% for training, 20% for testing

# Split the data into training and testing sets
train_data <- monthly_data[1:n_train, ]
test_data <- monthly_data[(n_train + 1):n_rows, ]
View(train_data)
View(test_data)
train_ts = ts(train_data$Monthly.minimum.temperatures,start = c(1981, 1), frequency = 12)
test_ts = ts(test_data$Monthly.minimum.temperatures,start = c(1989,1),frequency = 12)

# Fit a time series model to the training data (e.g., ARIMA(p,d,q))
library(forecast)

model1 = arima(train_ts,order = c(6,1,2))
model1 # aic = 327.49
summary(model1)
# Forecast future values using the fitted model
forecast1 <- forecast(model1, h = length(test_ts))
forecast1
# Evaluate the model's performance
accuracy(forecast1, test_ts)
plot(forecast1)
mean(abs((forecast1$mean - test_data$Monthly.minimum.temperatures)/test_data$Monthly.minimum.temperatures))

# Calculate residuals
residuals1 <- test_data$Monthly.minimum.temperatures - forecast1$fitted
# Plot residuals
plot(residuals1)



####### To check through auto.arima ######
model_auto <- auto.arima(train_data$Monthly.minimum.temperatures)
model_auto 
summary(model_auto) # AIC=323.55 ARIMA(4,0,1)

# Forecast future values using the fitted model
forecast2 <- forecast(model_auto, h = length(test_ts))
forecast2
# Evaluate the model's performance
plot(forecast2)
mean(abs((forecast2$mean - test_data$Monthly.minimum.temperatures)/test_data$Monthly.minimum.temperatures))

"Mean absolute percentage error of auto. arima (4,0,1) is  0.1171992
while that of ARIMA(6,1,2) is 0.115458 "

# Calculate residuals
residuals2 <- test_data$Monthly.minimum.temperatures - forecast2$fitted
# Plot residuals
plot(residuals2)


###### to check through exponential smoothing method #####
tempets = ets(train_data$Monthly.minimum.temperatures)
tempets
summary(tempets) # MAE 2.082431
# ETS(A,Ad,N)  aic = 571.4934
plot(tempets)
forecastets = forecast(tempets,h = nrow(test_data))
forecastets
plot(forecastets)

###### to check with holtz model ######
holt_model =  holt(train_ts)
summary(holt_model) # AIC is 578.1052
foreholt = forecast(holt_model,h = 10)
foreholt
plot(foreholt)

de = decompose(train_ts)
de # additive trend seasonality present
summary(de)
plot(de)
#incresing trend
#seasonality present

#### to check through seasonal differencing

seasonal_diff = diff(temp_ts_filled,lag=12)
plot(seasonal_diff)
acf(seasonal_diff) # q=1
pacf(seasonal_diff) #p = 1
adf.test(seasonal_diff) #p-value = 0.04433 < 0.05 ie stationary
kpss.test(seasonal_diff) #p-value = 0.1 > 0.5 ie stationary
# p=1, q=1 , d'= 1
model_1 = arima(train_ts,order = c(1,0,1), seasonal= list(order = c(0,1,0),period=12))
model_1 # aic = 285.66
# Forecast future values using the fitted model
forecast_1 <- forecast(model_1, h = length(test_ts))
forecast_1
# Evaluate the model's performance
accuracy(forecast_1, test_ts)
plot(forecast_1)
mean(abs((forecast_1$mean - test_data$Monthly.minimum.temperatures)/test_data$Monthly.minimum.temperatures))

"Mean absolute percentage error of auto. arima (4,0,1) is  0.1171992
while that of ARIMA(6,1,2) is 0.115458 
ARIMA(1,0,1)(0,1,0)[12] is 0.1067681
so the least MAPE is for the model with seasonal differencing, So we consider that model."




