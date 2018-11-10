---
title: "Predicting Loan Defaults with Logistic Regression"
date: 2018-08-17
tags: [Data Science]
header:
  image: "/images/fargo/testheader2.jpeg"
excerpt: "Predictive Logistic Regression"
---
## Section 1: Executive Summary
This analysis was conducted with the purpose of optimizing the profit from loans for the bank by predicting the outcome of a potential loan. We are interested in predicting the likelihood that a potential customer will have a 'good' or a 'bad' outcome on their loan, which in turn will result in whether or not the loan is paid back to the bank.

During the course of the analysis we determined which type of model should be used, which variables we should include into that model, as well as we validated the model to determine the accuracy of the predictions. The detailed methods can be found throughout the remainder of the report. The model that was used to predict the outcome of these loans is called a logistic regression model. This type of model can take many different predictor variables into consideration, and ultimately the outcome is the likelihood of a certain event occurring, in this case whether the outcome of a loan is 'good' or 'bad'. We went through the variables that were given in the original data set and were able to determine which would be the best predictors of loan outcomes. Once we had the model constructed we were able to determine the accuracy of the model through a method known as cross-validation. In this method we create a testing data set and a training data set as subsets from the original data. The training data is used to determine the coefficients of the model and then we use that model to 'predict' the outcomes of the testing set. We then compare the accuracy of our model, whether we correctly predicted the outcome of the loan as 'good' or 'bad'. Using the model we accurately predicted the outcome of the loan almost 80% of the time.

Ultimately the goal of this analysis is to be able to create a model which optimizes the amount of profit that the bank receives. With a logistic regression model the output is a proportion between 0 and 1, and the classification value is the point at which we consider the outcome to be a 'good' loan or a 'bad' loan. The default value in this type of analysis is 0.5, but quite often the optimal classification value for accuracy is different than 0.5. We were able to determine that the optimal classification value for accuracy is 0.58. We also conducted this experiment with profit, to determine which value would lead to the most profit. In this case the optimal classification value for profit was the same as the optimal classification value for accuracy. This means that if the output prediction for any potential customer is above 0.58 we would predict that they would ultimately have a 'good' loan outcome and vice versa for those who's output value is below 0.58.  When this value is utilized, in conjunction with our previously stated model, we are able to optimize the profit from the 50,000 loans to $2,787,819.

We suggest that the bank adopts this model in determining which potential customers should be approved for loans. It should be noted that due to the fact that there are unforeseen factors which could effect the outcome of a loan, the bank should utilize this model in conjunction with traditional underwriting techniques. If this takes place, we can cut down on the number of unprofitable loans for the bank and drive profit forward.


## Section 2: Introduction
For the purpose of this analysis, we are interested in predicting the likelihood that a potential customer will have a 'good' or a 'bad' outcome on a loan. We have a dataset containing data on 50,000 loans that will assist in the creation of our prediction model. In order to use this data for our model it will need to be cleaned and prepared for the analysis. In order to predict the likelihood of defaulting on a loan, we will use a logistic regression model. The reason that this model is the most appropriate, is because the outcome we are trying to predict is a binary response, either they will default or they will not. Throughout this report we will document the steps of the data cleansing, analysis, model preparation and implementation.

## Section 3: Preparing and Cleaning the Data
