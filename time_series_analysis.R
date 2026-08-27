# ------------------------------------------------------------------------------
# ARIMA ISPE Code 
# Author: Dorsa Ghahramani
# Date: August 2026
# ------------------------------------------------------------------------------



# Load packages ----------------------------------------------------------------

# If you don't have these packages installed yet, run install.packages("x") in 
# the console, where x is the package name (e.g., install.packages("here"))

library(readr)
library(here)
library(dplyr)
library(zoo)
library(forecast)
library(astsa)
library(uroot)
library(tseries)
library(lmtest)
library(ggplot2)
library(lmtest)



# Time series analysis ---------------------------------------------------------

# Read the data
df <- read_csv(here("opioid_weekly_claim.csv"))

# Convert the data set to time-series object
df_ts <- ts(
  data = df$N_Opioid,
  frequency = 52,  ## weekly data 
  start = c(2019, 1)  ## start time series at 2019 w1
)

# Define the step variable
(step <- as.numeric(as.yearmon(time(df_ts)) >= "2020-04-05"))

# Plot the data
plot(
  df_ts,
  ylim = c(80,440),
  xaxt = "n",
  type = 'l',
  col = "blue",
  xlab = "Week",
  ylab = "Number of Opioid",
  main = "Weekly Opioid Prescriptions"
)
axis(
  1,
  at = seq(2019,2021, by = 1/12) [1:24],
  labels =rep( month.abb,2),
  las = 2,
  cex.axis = 0.8
)
axis(
  1,
  at = seq(2019,2020),
  labels =c("2019" , "2020"),
  tick = FALSE,
  line = 1,
  cex.axis = 0.7
)
abline(
  v = 2020+ 13/52,
  col = "gray",
  lty = "dashed",
  lwd = 2
)

# ACF and PACF
ggtsdisplay(df_ts, lag.max = 24)

# ACF and PACF (d=1)
ggtsdisplay(diff(df_ts) , lag.max = 24)

# Run the model with 0-1-1
model_011 <- Arima(
  df_ts,
  order = c(0, 1, 1),
  xreg = cbind(step)
  # include.drift = TRUE
)
residuals_model_011 <- residuals(model_011)

# Check ACF and PACF again: satisfying now (within blue bounds)
ggtsdisplay(residuals_model_011, lag.max = 24)

# Box test
Box.test(
  residuals_model_011,
  lag = 24,
  type = "Ljung-Box",
  fitdf = 2 
)

# auto model
model_auto <- auto.arima(df_ts)
summary(model_auto)

residuals_model_auto <- residuals(model_auto)

# Check ACF and PACF again: satisfying now (within blue bounds)
ggtsdisplay(residuals_model_auto, lag.max = 24)

# Box test
Box.test(
  residuals_model_auto,
  lag = 24,
  type = "Ljung-Box",
  fitdf = 2 
)

# Forecasting
future_step <- rep(1,24)
forecast_arima <- forecast(
  model_auto,
  h=24,
  xreg = future_step
)
autoplot(forecast_arima,
         fcol =  "aquamarine3",
         PI = TRUE) +
  scale_x_continuous(
    breaks = seq(2019,2021 + 5/12, by = 1/12),
    labels = rep(month.abb,3)[1:30]
  ) +
  labs(title = "ARIMA Model Forecast",
       x = "Time",
       y = "Number of Opioid Prescription"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90 , hjust = 1))
