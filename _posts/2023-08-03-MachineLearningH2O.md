---
title: "Machine Learning with H2O"
date: 2023-08-03
tags: [Data Science]
header:
  image: "/images/fargo/testheader2.jpeg"
excerpt: "Machine Learning w/H2O"
---

# Introduction
*Due to the proprietary nature of my work these are examples of recent work completed*

Utilizing H2O is an open source platform that makes it easy for companies to utilize Big Data to deploy AI and deep learning to solve complex problems. In my experience I have used H2O in the final data preparation stages of the modeling process, the training process, validation process and model selection process. I have similar experience with SparklyR - and both are comparable but with the robustness of H2O we are able to train on much larger datasets. Below is an example of a potential use-case of taking a data set and fitting multiple models to that dataset and determining which performs the best.



# Libraries

```r
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#--| Call Libraries
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(h2o)
library(h2osteam)

library(dplyr)
library(sparklyr)
library(svDialogs)
library(RCurl)
library(ggplot2)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

```
# Set Up Connection

```r
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#--| Connection Setup
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~
steam_url = "enter_your_steam_url_here"
id = 'user123' #enter your userID
cluster_name = "Example_H2O_Cluster" #customize as needed
h2o_version = "3.33.1.5511"
node_memory = "5G"
num_nodes = 2
key = 123456789 #example

password = dlgInput("Enter password", Sys.info()["user"])$res

source('encryption.R') #R file containing encryption for connection

conn = h20steam.login(url = steam_url,
                      username = id,
                      password = decrypt(cipher_text, key),
                      verify_ssl = FALSE)

conf = h20steam.start_h20_cluster(
  conn = conn,
  cluster_name = paste(cluster_name,id,sep = "-"),
  node_memory = node_memory,
  num_nodes = num_nodes,
  h20_version = h2o_version,
  yarn_queue = 'yourQueue',
  max_idle_time = 8,
  max_uptime = 14,
  profile_name = 'default-h2o'

  )

h2o.connect(config = conf$connect_params)
h2o.ls()


```
# Read In Data
```r
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#--| Read In Data
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~

des = read.hive('desc example_schema.your_database')$col_name #read.hive being custom function to read data from Hadoop
hdfsDatabase_loc = paste0('hdfs://location/for/your/database')

base_table_2023 = h2o.importFile(path = hdfsDatabase_loc, destination_frame="datatable_name", col.names = des)

# Perform Column Data Type Manipulation as needed
base_table_2023$col1 = as.factor(base_table_2023$col1)

# Final Creation of Target Variable
base_table_2023$response_var = ifelse(is.na(base_table_2023$response),0,base_table_2023$response)

# Summary of Response by Key Column for reference
col1_sum = h2o.group_by(data = base_table_2023,
                        by = 'col1',
                        sum("response_var"),
                        nrow("response_var", na="ignore"));col1_sum




```

# Data Preparation Before Modeling
```r
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#--| Data Preparation Before Modeling
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Summary of Class Distribution
minority_class_index_total= base_table_2023[,'response_var'] == 1
minority_class_total = base_table_2023[minority_class_index_total,]
nrow.H2OFrame(minority_class_total); nrow.H2OFrame(base_table_2023);nrow.H2OFrame(minority_class_total)/ nrow.H2OFrame(base_table_2023)

# Create Test and Training Sets
partitions <- h2o.splitFrame(data = base_table_2023, ratios = 0.8, seed = 4321)

dt_train <- partitions[[1]]
dt_test <- partitions[[2]]

minority_class_index = dt_train[,'response_var'] == 1
minority_class = dt_train[minority_class_index,]

majority_class_index =  dt_train[,'response_var'] == 0
majority_class = dt_train[majority_class_index,]
n_split =nrow.H2OFrame(minority_class)

train_sum = h2o.group_by(data = dt_train, by = "response_var", nrow("response_var"));train_sum
n_total = nrow.H2OFrame(dt_train)


# Example Balancing of Classes for Imbalanced Data
sample_majority_class = h2o.splitFrame(data = majority_class, ratios = n_split/n_total, seed = 4321)

sample_majority_class = sample_majority_class[[1]]

h2o.nrow(sample_majority_class)
h2o.describe(sample_majority_class)


combined_balanced = h2o.rbind(minority_class, sample_majority_class)

# Data Checks
balanced_sum = h2o.group_by(data = combined_balanced, by = "response_var", nrow("response_var"));balanced_sum
total_n = h2o.nrow(combined_balanced)

combined_balanced$response_var <- as.factor(combined_balanced$response_var)

df_splits <- h2o.splitFrame(data =combined_balanced, ratios = 0.8, seed = 4321)

train <- df_splits[[1]]
test <- df_splits[[2]]

predictors <- colnames(train[ ,!(colnames(train) == "response_var")])
response <- "response_var"

```

# Model Construction and Evaluation

### Logistic Regression
```r
#~~~~~~~~~~~~~~~~~~~~~~~~
#--| Logistic Regression
#~~~~~~~~~~~~~~~~~~~~~~~~
#https://docs.h2o.ai/h2o/latest-stable/h2o-docs/training-models.html#classification-example

glm_fit1 <- h2o.glm(family = "binomial",
                    x = predictors,
                    y = response,
                    training_frame = train,
                    lambda = 0,
                    compute_p_values = TRUE,
                    balance_classes = TRUE,
                    remove_collinear_columns = TRUE,
                    nfolds = 5)

# AUC of cross-validated holdout predictions
h2o.auc(glm_fit1, xval = TRUE)

# Prediction
glm_fit1_predict <- h2o.predict(object = glm_fit1, newdata = test)
h2o.head(glm_fit1_predict)

#Check Coefficient & Summary
#https://docs.h2o.ai/h2o/latest-stable/h2o-docs/performance-and-prediction.html

h2o.coef(glm_fit1)

# Coefficients fitted on the standardized data (requires standardize=TRUE, which is on by default)
h2o.coef_norm(glm_fit1)

# Print the coefficients table
glm_fit1_summary <- glm_fit1@model$coefficients_table

# If Interested in only significant coefficients
#glm_fit1_summary$names[glm_fit1_summary$p_value <= 0.05]


h2o.varimp_plot(glm_fit1)
glm_fit1_varimp <- h2o.varimp(glm_fit1)

glm_fit1_perf <- h2o.performance(glm_fit1, test)
glm_fit1_perf

glm_fit1_perf_original <- h2o.performance(glm_fit1, dt_test)
glm_fit1_perf_original

pred_vs_actual_glm <- as.data.frame(h2o.cbind(test$response_var,glm_fit1_predict$predict, glm_fit1_predict$p1))



write.csv(glm_fit1_perf@metrics$cm$table,'lr_cm.csv')
write.csv(glm_fit1_summary, 'logregressionh20.csv')

```

### Random Forest
```r
#~~~~~~~~~~~~~~~~~~~~~~~~
#--| Random Forest
#~~~~~~~~~~~~~~~~~~~~~~~~

# http://h2o-release.s3.amazonaws.com/h2o/rel-yu/2/docs-website/h2o-docs/data-science/drf.html

rf_fit1 <- h2o.randomForest(x = predictors,
                            y = response,
                            training_frame = train,
                            nfolds = 5,
                            balance_classes = TRUE,
                            seed = 1234)

# AUC of cross-validated holdout predictions
h2o.auc(rf_fit1, xval = TRUE)

# Prediction
rf_fit1_predict <- h2o.predict(object = rf_fit1, newdata = test)
h2o.head(rf_fit1_predict)

# Model performance
rf_fit1_summary <- rf_fit1@model$summary
h2o.varimp_plot(rf_fit1)
rf_fit1_varimp <- h2o.varimp(rf_fit1)

rf_fit1_perf <- h2o.performance(rf_fit1, test)
rf_fit1_perf

rf_fit1_perf_orig <- h2o.performance(rf_fit1, dt_test)
rf_fit1_perf_orig

pred_vs_actual_rf <- as.data.frame(h2o.cbind(test$response_var,rf_fit1_predict$predict, rf_fit1_predict$p1))


write.csv(rf_fit1_perf@metrics$cm$table, 'rf_cm.csv')
write.csv(rf_fit1_varimp, 'rf_varimph2o.csv')

```

### XGBoost
```r
#~~~~~~~~~~~~~
#--| XGBoost
#~~~~~~~~~~~~~
xgb_fit1 <- h2o.xgboost(x = predictors,
                       y = response,
                       training_frame = train,
                       #validation_frame = test,
                       booster = "dart",
                       normalize_type = "tree",
                       seed = 1234)

# AUC of cross-validated holdout predictions
#h2o.auc(xgb_fit1, xval = TRUE)
h2o.performance(xgb_fit1)

# Prediction
xgb_fit1_predict <- h2o.predict(object = xgb_fit1, newdata = test)
h2o.head(xgb_fit1_predict)

# Model performance
xgb_fit1_summary <- xgb_fit1@model$summary
h2o.varimp_plot(xgb_fit1)
xgb_fit1_varimp <- h2o.varimp(xgb_fit1)

xgb_fit1_perf <- h2o.performance(xgb_fit1, test)
xgb_fit1_perf

xgb_fit1_perf_orig <- h2o.performance(xgb_fit1, dt_test)
xgb_fit1_perf_orig

pred_vs_actual_xgb <- as.data.frame(h2o.cbind(test$response_var,xgb_fit1_predict$predict, xgb_fit1_predict$p1))

write.csv(xgb_fit1_perf@metrics$cm$table, 'xgb_cm.csv')
write.csv(xgb_fit1_varimp, 'xgb_varimph2o.csv')


```

# Lift and Gain Assessment

```r
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#--| Lift and Gain Calculation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
lift <- function(depVar, predCol, ratingCol, groups=10) {
  # Function built for the purpose of calculating Lift and Gain of predictive model

  if(is.factor(depVar)) depVar <- as.integer(as.character(depVar))
  if(is.factor(predCol)) predCol <- as.integer(as.character(predCol))

  helper = data.frame(cbind(depVar, predCol, ratingCol))
  helper = as.data.frame(helper %>% mutate(rank = dense_rank(desc(ratingCol))) %>% arrange(rank))
  helper[,"bucket"] =ntile(-helper[,"predCol"], groups)

  gaintable = helper %>% group_by(bucket)  %>%
    summarise_at(vars(depVar), funs(total = n(),
                                    totalresp=sum(., na.rm = TRUE))) %>%
    mutate(Cumresp = cumsum(totalresp),
           Gain=Cumresp/sum(totalresp)*100,
           Cumlift=Gain/(bucket*(100/groups)))

  return(gaintable)

}

# Logistic Regression
dt_glm = lift(pred_vs_actual_glm$response_var , pred_vs_actual_glm$predict, pred_vs_actual_glm$p1, groups = 10)
dt_glm
# Random Forest
dt_rf = lift(pred_vs_actual_rf$response_var , pred_vs_actual_rf$predict, pred_vs_actual_rf$p1, groups = 10)
dt_rf
# XGBoost
dt_xgb = lift(pred_vs_actual_xgb$response_var , pred_vs_actual_xgb$predict, pred_vs_actual_xgb$p1, groups = 10)
dt_xgb

# Example Gain Chart
ggplot(data = dt_xgb, aes(x = bucket))+
  geom_line(aes(y = Gain/100), color = "darkred") +
  geom_abline(slope=1, intercept=0) +
  ggtitle("Gain Chart for XGBoost") +
  xlab("Decile") + ylab("Gain")

# Example Lift Chart
ggplot(data = dt_xgb, aes(x = bucket))+
  geom_line(aes(y = Cumlift), color = "darkred") +
  ggtitle("Lift Chart for XGBoost") +
  xlab("Percentile") + ylab("Lift")

```
