####==================================================================####

#Set up packages

#https://github.aetna.com/analytics-org/h2o-packages




#remove.packages(c("h2o","h2osteam"))

#install.packages(c('RCurl', 'jsonlite','digest'), dependencies = T)

#install.packages("https://github.aetna.com/analytics-org/h2o-packages/raw/master/3.33.1.5511/R/h2o_3.33.1.5511.tar.gz", repos = NULL)

#install.packages("https://github.aetna.com/analytics-org/h2o-packages/raw/master/steam/h2osteam_1.4.8.tar.gz", repos = NULL)




#pkgs <- c('DBI', 'RJDBC', 'rJava', 'lubridate', 'rhdfs', 'digest', 'rstudioapi')

#install.packages(pkgs, dependencies = T)

#install.packages("https://github.aetna.com/analytics-org/aetnar/raw/master/dist/aetnar_0.2.2.tar.gz", repos = NULL)










####==================================================================####

#Call libraries

library(aetnar)

library(RCurl)

library(sparklyr)

library(dplyr)

library(svDialogs)

#change_password() # only need to run once




library(h2o)

library(h2osteam)




setwd(dirname(rstudioapi::getActiveDocumentContext()$path))







####==================================================================####

#Set up connection

#https://github.aetna.com/analytics-org/h2o-packages




steam_url <- "https://xhadsteam2p.aetna.com:9000"   #Can login through link to setup manually

aid <- "a375314"

#aid <- system('whoami', intern = T)

cluster_name <- "MC_mod"             #Customize yourself

#queue_name <- "devanalytics"    #Run in Edgenode(see doc): mapred queue -showacls 2>/dev/null | grep SUBMIT_APPLICATIONS | awk '{print $1}'

h2o_version <- "3.33.1.5511"     #Get latest available version

node_memory <- "5G"

num_nodes <- 2

key=19951004




#load(paste("~/",aid,".profile",sep = "") )

#spswd<- trimws(read_file("~/.pswd"))

#test = readRDS('~/R/.encrypted_password.RDS')

#password = decrypt(readRDS('~/R/.encrypted_password.RDS'),key)




password <- dlgInput("Enter password", Sys.info()["user"])$res




source('encryption.R')

# Login to Steam. #Run encryption script first

# If error, Restart R & Clean enviornment and re-run encryption script

conn <- h2osteam.login(url      = steam_url,

                       username = aid,

                       password =  decrypt(cipher_text,key),

                       verify_ssl = FALSE)



















conf <- h2osteam.start_h2o_cluster(

  conn = conn,

  cluster_name =  paste(cluster_name,aid,sep = "-"),

  node_memory = node_memory,

  num_nodes = num_nodes,

  h2o_version = '3.33.1.5511',

  yarn_queue = 'devanalytics',

  max_idle_time = 8,

  max_uptime = 14,

  profile_name = "default-h2o")







h2o.connect(config = conf$connect_params)

h2o.ls()













####==================================================================####

# Load data

# Need to move tables into HDFS, can be done by running following query

# create table dev_rx_benefit_enc.{hdfs_table_nm}

# Stored as Parquet as

# select * from dev_rx_benefit_enc.a520769_mc_modeling_features_2019_rxmodel_all;

# install.packages('odbc')

# devtools::install_version("odbc", version = "1.2.2")

# hc <- dbConnect(odbc::odbc(), "hive2", timeout = 10)

# kerberos_auth <- function(aid = toupper(system("whoami", intern=T)), keytab_path = glue::glue("~/{system('whoami',intern=T)}.keytab")){

#   system(glue::glue("kinit {aid}@AETH.AETNA.COM -k -t {keytab_path}"))

# }

# dbGetQuery(hc, "select whatever from whatever")

# DBI::dbListFields(hc, SQL("desc dev_rx_benefit_enc.a375314_mc_modeling_features_2019_mcmodel_all"))




des <- read.hive("desc dev_rx_benefit_enc.a375314_mc_modeling_features_2019_mcmodel_all")$col_name




hdfsDatabase <- paste0("hdfs://prodmid:8020/dev/derived/value_analytics/rx_benefit/a375314_mc_modeling_features_2019_mcmodel_all/000000_0")

mc_master_2019 <- h2o.importFile(path=hdfsDatabase, destination_frame="a375314_mc_modeling_features_2019_mcmodel_all" , col.names=des)




mc_master_2019$cvs_cohort = as.factor(mc_master_2019$cvs_cohort)

mc_master_2019$rx_member_months = as.factor(mc_master_2019$rx_member_months)

mc_master_2019$age_group = as.factor(mc_master_2019$age_group)

mc_master_2019$segment = as.factor(mc_master_2019$segment)

mc_master_2019$business_ln_cd = as.factor(mc_master_2019$business_ln_cd)

mc_master_2019$gender_cd = as.factor(mc_master_2019$gender_cd)

mc_master_2019$member_months = as.factor(mc_master_2019$member_months)

mc_master_2019$rx_ind_indvdl = as.factor(mc_master_2019$rx_ind_indvdl)

mc_master_2019$fund_ctg_cd = as.factor(mc_master_2019$fund_ctg_cd)

#mc_master_2019$drug_ind = as.factor(mc_master_2019$drug_ind)




h2o.unique(mc_master_2019$rx_member_months)




agegroup_sum = h2o.group_by(data = mc_master_2019, by = "age_group", sum("minute_clinic_visit_response"), nrow('minute_clinic_visit_response')  );agegroup_sum




des_v2 <- read.hive("desc dev_rx_benefit_enc.a375314_mc_modeling_features_2019_mcmodel_future")$col_name

hdfsDatabase_v2 <- paste0("hdfs://prodmid:8020/dev/derived/value_analytics/rx_benefit/a375314_mc_modeling_features_2019_mcmodel_future/000000_0")

mc_master_2019_v2 <- h2o.importFile(path=hdfsDatabase_v2, destination_frame="a375314_mc_modeling_features_2019_mcmodel_all_future", col.names=des_v2)




mc_master_2019_v2$cvs_cohort = as.factor(mc_master_2019_v2$cvs_cohort)

mc_master_2019_v2$rx_member_months = as.factor(mc_master_2019_v2$rx_member_months)

mc_master_2019_v2$age_group = as.factor(mc_master_2019_v2$age_group)

mc_master_2019_v2$segment = as.factor(mc_master_2019_v2$segment)

mc_master_2019_v2$business_ln_cd = as.factor(mc_master_2019_v2$business_ln_cd)

mc_master_2019_v2$gender_cd = as.factor(mc_master_2019_v2$gender_cd)

mc_master_2019_v2$member_months = as.factor(mc_master_2019_v2$member_months)

mc_master_2019_v2$rx_ind_indvdl = as.factor(mc_master_2019_v2$rx_ind_indvdl)

mc_master_2019_v2$fund_ctg_cd = as.factor(mc_master_2019_v2$fund_ctg_cd)

#mc_master_2019_v2$drug_ind = as.factor(mc_master_2019_v2$drug_ind)




mc_master_2019_v2$minute_clinic_visit_response_future = ifelse(is.na(mc_master_2019_v2$minute_clinic_visit_response_future),0,mc_master_2019_v2$minute_clinic_visit_response_future)




#agegroup_sum = h2o.group_by(data = mc_master_2019_v2, by = "age_group", sum("minute_clinic_visit_response_future"), nrow('minute_clinic_visit_response_future')  );agegroup_sum




lob_sum = h2o.group_by(data = mc_master_2019_v2,

                       by = "business_ln_cd",

                       sum("minute_clinic_visit_response_future"),

                       nrow('minute_clinic_visit_response_future',

                            na="ignore"));lob_sum







####==================================================================####

# Data preparation before modeling

h2o.describe(mc_master_2019)






















minority_class_index_total= mc_master_2019[,'minute_clinic_visit_response'] == 1

minority_class_total = mc_master_2019[minority_class_index_total,]

nrow.H2OFrame(minority_class_total); nrow.H2OFrame(mc_master_2019);nrow.H2OFrame(minority_class_total)/ nrow.H2OFrame(mc_master_2019)










#h2o.getTypes(mc_master_2019$minute_clinic_visit_response)

#mc_master_2019$minute_clinic_visit_response <- as.factor(mc_master_2019$minute_clinic_visit_response)




#df <- h2o.splitFrame(data = mc_master_2019, ratios = 0.5, seed = 4321)

#dim(df[[1]])










partitions <- h2o.splitFrame(data = mc_master_2019, ratios = 0.8, seed = 4321)







mc_train <- partitions[[1]]

mc_test <- partitions[[2]]




minority_class_index = mc_train[,'minute_clinic_visit_response'] == 1

minority_class = mc_train[minority_class_index,]







majority_class_index =  mc_train[,'minute_clinic_visit_response'] == 0

majority_class = mc_train[majority_class_index,]




n_split =nrow.H2OFrame(minority_class)










train_sum = h2o.group_by(data = mc_train, by = "minute_clinic_visit_response", nrow("minute_clinic_visit_response"));train_sum







#n_split = nrow.H2OFrame(train_pos)

n_total = nrow.H2OFrame(mc_train)




#majority_class = mc_train %>% filter(minute_clinic_visit_response == 0)

#minority_class = mc_train %>% filter(minute_clinic_visit_response == 1)




sample_majority_class = h2o.splitFrame(data = majority_class, ratios = n_split/n_total, seed = 4321)

sample_majority_class = sample_majority_class[[1]]

h2o.nrow(sample_majority_class)

#sdf_sample(majority_class,fraction = n_split/n_total,replacement = FALSE, seed = 1111 )




h2o.describe(sample_majority_class)




combined_balanced = h2o.rbind(minority_class, sample_majority_class)

balanced_sum = h2o.group_by(data = combined_balanced, by = "minute_clinic_visit_response", nrow("minute_clinic_visit_response"));balanced_sum




total_n = h2o.nrow(combined_balanced)




combined_balanced$minute_clinic_visit_response <- as.factor(combined_balanced$minute_clinic_visit_response)




df_splits <- h2o.splitFrame(data =combined_balanced, ratios = 0.8, seed = 4321)

train <- df_splits[[1]]

test <- df_splits[[2]]




predictors <- colnames(train[ ,!(colnames(train) == "minute_clinic_visit_response")])

response <- "minute_clinic_visit_response"










####==================================================================####

# Logistic Regression

# https://docs.h2o.ai/h2o/latest-stable/h2o-docs/training-models.html#classification-example

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




# Check Coefficient & Summary

# https://docs.h2o.ai/h2o/latest-stable/h2o-docs/performance-and-prediction.html




h2o.coef(glm_fit1)

# Coefficients fitted on the standardized data (requires standardize=TRUE, which is on by default)

h2o.coef_norm(glm_fit1)




# Print the coefficients table

glm_fit1_summary <- glm_fit1@model$coefficients_table

#glm_fit1_summary$names[glm_fit1_summary$p_value <= 0.05]




h2o.varimp_plot(glm_fit1)

glm_fit1_varimp <- h2o.varimp(glm_fit1)




glm_fit1_perf <- h2o.performance(glm_fit1, test)

glm_fit1_perf




glm_fit1_perf_original <- h2o.performance(glm_fit1, mc_test)

glm_fit1_perf_original




write.csv(glm_fit1_perf@metrics$cm$table,'lr_cm.csv')




write.csv(glm_fit1_summary, 'logregressionh20.csv')




####==================================================================####

# Random Forest

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




rf_fit1_perf_orig <- h2o.performance(rf_fit1, mc_test)

rf_fit1_perf_orig










write.csv(rf_fit1_perf@metrics$cm$table, 'rf_cm.csv')




write.csv(rf_fit1_varimp, 'rf_varimph2o.csv')
















####==================================================================####

# XGBoost

#

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




xgb_fit1_perf_orig <- h2o.performance(xgb_fit1, mc_test)

xgb_fit1_perf_orig










write.csv(xgb_fit1_perf@metrics$cm$table, 'xgb_cm.csv')




write.csv(xgb_fit1_varimp, 'xgb_varimph2o.csv')







#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




# Re-do with 2019 data to predict 2020 results




####==================================================================####

# Data preparation before modeling

h2o.describe(mc_master_2019_v2)







#h2o.getTypes(mc_master_2019$minute_clinic_visit_response)

#mc_master_2019$minute_clinic_visit_response <- as.factor(mc_master_2019$minute_clinic_visit_response)




#df <- h2o.splitFrame(data = mc_master_2019, ratios = 0.5, seed = 4321)

#dim(df[[1]])










partitions2 <- h2o.splitFrame(data = mc_master_2019_v2, ratios = 0.8, seed = 4321)







mc_train2 <- partitions2[[1]]

mc_test2 <- partitions2[[2]]




minority_class_index2 = mc_train2[,'minute_clinic_visit_response_future'] == 1

minority_class2 = mc_train2[minority_class_index2,]




majority_class_index2 =  mc_train2[,'minute_clinic_visit_response_future'] == 0

majority_class2 = mc_train2[majority_class_index2,]




n_split2 =nrow.H2OFrame(minority_class2)







train_sum2 = h2o.group_by(data = mc_train2, by = "minute_clinic_visit_response_future", nrow("minute_clinic_visit_response_future"));train_sum2







#n_split = nrow.H2OFrame(train_pos)

n_total2 = nrow.H2OFrame(mc_train2)




#majority_class = mc_train %>% filter(minute_clinic_visit_response == 0)

#minority_class = mc_train %>% filter(minute_clinic_visit_response == 1)




sample_majority_class2 = h2o.splitFrame(data = majority_class2, ratios = n_split2/n_total2, seed = 4321)

sample_majority_class2 = sample_majority_class2[[1]]

h2o.nrow(sample_majority_class2)

#sdf_sample(majority_class,fraction = n_split/n_total,replacement = FALSE, seed = 1111 )




h2o.describe(sample_majority_class2)




combined_balanced2 = h2o.rbind(minority_class2, sample_majority_class2)

balanced_sum2 = h2o.group_by(data = combined_balanced2, by = "minute_clinic_visit_response_future", nrow("minute_clinic_visit_response_future"));balanced_sum2




combined_balanced2$minute_clinic_visit_response_future <- as.factor(combined_balanced2$minute_clinic_visit_response_future)




total_n2 = h2o.nrow(combined_balanced2)







df_splits2 <- h2o.splitFrame(data =combined_balanced2, ratios = 0.8, seed = 4321)

train2 <- df_splits2[[1]]

test2 <- df_splits2[[2]]




predictors2 <- colnames(train2[ ,!(colnames(train2) == "minute_clinic_visit_response_future")])

response2 <- "minute_clinic_visit_response_future"










####==================================================================####

# Logistic Regression

# https://docs.h2o.ai/h2o/latest-stable/h2o-docs/training-models.html#classification-example

glm_fit2 <- h2o.glm(family = "binomial",

                    x = predictors2,

                    y = response2,

                    training_frame = train2,

                    lambda = 0,

                    compute_p_values = TRUE,

                    balance_classes = TRUE,

                    remove_collinear_columns = TRUE,

                    nfolds = 5)




# AUC of cross-validated holdout predictions

h2o.auc(glm_fit2, xval = TRUE)




# Prediction

glm_fit2_predict <- h2o.predict(object = glm_fit2, newdata = test2)

h2o.head(glm_fit2_predict)




# Check Coefficient & Summary

# https://docs.h2o.ai/h2o/latest-stable/h2o-docs/performance-and-prediction.html




h2o.coef(glm_fit2)

# Coefficients fitted on the standardized data (requires standardize=TRUE, which is on by default)

h2o.coef_norm(glm_fit2)




# Print the coefficients table

glm_fit2_summary <- glm_fit2@model$coefficients_table

#glm_fit1_summary$names[glm_fit1_summary$p_value <= 0.05]










h2o.varimp_plot(glm_fit2)

glm_fit2_varimp <- h2o.varimp(glm_fit2)




glm_fit2_perf <- h2o.performance(glm_fit2, test2)

glm_fit2_perf




pred_vs_actual_glm <- as.data.frame(h2o.cbind(test2$minute_clinic_visit_response_future,glm_fit2_predict$predict, glm_fit2_predict$p1))




glm_fit2_perf_orig <- h2o.performance(glm_fit2, mc_test2)

glm_fit2_perf_orig




glm_fit2_predict_orig <- h2o.predict(object = glm_fit2, newdata = mc_test2)

h2o.head(glm_fit2_predict_orig)




pred_vs_actual_glm_orig =  as.data.frame(h2o.cbind(mc_test2$minute_clinic_visit_response_future,glm_fit2_predict_orig$predict, glm_fit2_predict_orig$p1))







write.csv(glm_fit2_perf@metrics$cm$table,'lr_cm_future.csv')




write.csv(glm_fit2_summary, 'logregressionh20_future.csv')







####==================================================================####

# Random Forest

# http://h2o-release.s3.amazonaws.com/h2o/rel-yu/2/docs-website/h2o-docs/data-science/drf.html

rf_fit2 <- h2o.randomForest(x = predictors2,

                            y = response2,

                            training_frame = train2,

                            nfolds = 5,

                            balance_classes = TRUE,

                            seed = 1234)




# AUC of cross-validated holdout predictions

h2o.auc(rf_fit2, xval = TRUE)




# Prediction

rf_fit2_predict <- h2o.predict(object = rf_fit2, newdata = test2)

h2o.head(rf_fit2_predict)




# Model performance

rf_fit2_summary <- rf_fit2@model$summary

h2o.varimp_plot(rf_fit2)

rf_fit2_varimp <- h2o.varimp(rf_fit2)




rf_fit2_perf <- h2o.performance(rf_fit2, test2)

rf_fit2_perf




rf_fit2_perf_orig <- h2o.performance(rf_fit2, mc_test2)

rf_fit2_perf_orig




rf_fit2_predict_orig <- h2o.predict(object = rf_fit2, newdata = mc_test2)

h2o.head(rf_fit2_predict_orig)




pred_vs_actual_rf_orig =  as.data.frame(h2o.cbind(mc_test2$minute_clinic_visit_response_future,rf_fit2_predict_orig$predict, rf_fit2_predict_orig$p1))




write.csv(rf_fit2_perf_orig@metrics$cm$table, 'rf_cm_original.csv')







pred_vs_actual_rf <- as.data.frame(h2o.cbind(test2$minute_clinic_visit_response_future,rf_fit2_predict$predict, rf_fit2_predict$p1))







write.csv(rf_fit2_perf@metrics$cm$table, 'rf_cm_future.csv')




write.csv(rf_fit2_varimp, 'rf_varimph2o_future.csv')







####==================================================================####

# XGBoost

#

xgb_fit2 <- h2o.xgboost(x = predictors2,

                        y = response2,

                        training_frame = train2,

                        #validation_frame = test,

                        booster = "dart",

                        normalize_type = "tree",

                        seed = 1234)




# AUC of cross-validated holdout predictions

#h2o.auc(xgb_fit2, xval = TRUE)







h2o.performance(xgb_fit2)




# Prediction

xgb_fit2_predict <- h2o.predict(object = xgb_fit2, newdata = test2)

h2o.head(xgb_fit2_predict)




# Model performance

xgb_fit2_summary <- xgb_fit2@model$summary

h2o.varimp_plot(xgb_fit2)

xgb_fit2_varimp <- h2o.varimp(xgb_fit2)




xgb_fit2_perf <- h2o.performance(xgb_fit2, test2)

xgb_fit2_perf







xgb_fit2_perf_orig <- h2o.performance(xgb_fit2, mc_test2)

xgb_fit2_perf_orig




xgb_fit2_predict_orig <- h2o.predict(object = xgb_fit2, newdata = mc_test2)




xgb_fit2_perf_orig <- h2o.performance(xgb_fit2, mc_test2)

xgb_fit2_perf_orig







h2o.head(xgb_fit2_predict)

pred_vs_actual_xgb <- as.data.frame(h2o.cbind(mc_test2$minute_clinic_visit_response_future,xgb_fit2_predict_orig$predict, xgb_fit2_predict_orig$p1))




xgb_fit2_perf@metrics$cm$table

xgb_fit2_perf_orig@metrics$cm$table




pred_vs_actual_xgb_bal <- as.data.frame(h2o.cbind(test2$minute_clinic_visit_response_future,xgb_fit2_predict$predict, xgb_fit2_predict$p1))




write.csv(xgb_fit2_perf@metrics$cm$table, 'xgb_cm_future.csv')




write.csv(xgb_fit2_varimp, 'xgb_varimph2o_future.csv')










#write.csv(xgb_fit2_perf@metrics$AUC, 'xgb_performance.csv')
















# xgb_gainslift = h2o.gainsLift(xgb_fit2)

#

# plot(xgb_gainslift$group, xgb_gainslift$gain)

# plot(xgb_gainslift$group, xgb_gainslift$cumulative_gain)

#

# plot(xgb_gainslift$group, xgb_gainslift$cumulative_capture_rate)

#

#

#

# #plot(xgb_gainslift$cumulative_data_fraction, xgb_gainslift$cumulative_capture_rate, xgb_gainslift$cumulative_lift)

#

# library(ggplot2)

# ggplot(data = xgb_gainslift, aes(x = cumulative_data_fraction))+

#   geom_line(aes(y = cumulative_capture_rate), color = "darkred") +

#   geom_line(aes(y = cumulative_lift), color="steelblue", linetype="twodash")

#

#

# ggplot(data = xgb_gainslift, aes(x = group))+

#   geom_line(aes(y = cumulative_gain), color = "darkred") +

#   geom_abline(slope=1, intercept=0)

#   geom_line(aes(y = cumulative_lift), color="steelblue", linetype="twodash")

#

# h2o.gainsLift(xgb_fit2_perf)







library(dplyr)

library(ggplot2)




lift <- function(depVar, predCol, ratingCol, groups=10) {



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




dt_xgb = lift(pred_vs_actual_xgb$minute_clinic_visit_response_future , pred_vs_actual_xgb$predict, pred_vs_actual_xgb$p1, groups = 10)

dt_xgb

ggplot(data = dt_xgb, aes(x = bucket))+

  geom_line(aes(y = Gain/100), color = "darkred") +

  geom_abline(slope=1, intercept=0) +

  ggtitle("Gain Chart for XGBoost") +

  xlab("Decile") + ylab("Gain")
















dt_xgb2 = lift(pred_vs_actual_xgb$minute_clinic_visit_response_future , pred_vs_actual_xgb$predict, pred_vs_actual_xgb$p1, groups = 5)

dt_xgb2

ggplot(data = dt_xgb2, aes(x = bucket))+

  geom_line(aes(y = Gain/100), color = "darkred") +

  #geom_abline(slope=1, intercept=0) +

  ggtitle("Gain Chart for XGBoost") +

  xlab("Quintile") + ylab("Gain")




dt_xgb3 = lift(pred_vs_actual_xgb$minute_clinic_visit_response_future , pred_vs_actual_xgb$predict, pred_vs_actual_xgb$p1, groups = 100)

dt_xgb3

ggplot(data = dt_xgb3, aes(x = bucket))+

  geom_line(aes(y = Gain), color = "darkred") +

  geom_abline(slope=1, intercept=0) +

  ggtitle("Gain Chart for XGBoost") +

  xlab("Percentile") + ylab("Gain")




library(xlsx)

write.xlsx(dt_xgb, file = 'xgb_gains_updated.xlsx', sheetName = 'Decile')

#write.xlsx(dt_xgb2, file = 'random_forest_gains.xlsx', sheetName = 'Quintile', append = T)

write.xlsx(dt_xgb3, file = 'xgb_gains_updated.xlsx', sheetName = 'Percentile', append = T)




#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dt_rf = lift(pred_vs_actual_rf_orig$minute_clinic_visit_response_future , pred_vs_actual_rf_orig$predict, pred_vs_actual_rf_orig$p1, groups = 100)

dt_rf

ggplot(data = dt_rf, aes(x = bucket))+

  geom_line(aes(y = Gain), color = "darkred") +

  geom_abline(slope=1, intercept=0) +

  ggtitle("Gain Chart for Random Forest") +

  xlab("Percentile") + ylab("Gain")







dt_lr = lift(pred_vs_actual_glm_orig$minute_clinic_visit_response_future , pred_vs_actual_glm_orig$predict, pred_vs_actual_glm_orig$p1, groups = 100)

dt_lr

ggplot(data = dt_lr, aes(x = bucket))+

  geom_line(aes(y = Gain), color = "darkred") +

  geom_abline(slope=1, intercept=0) +

  ggtitle("Gain Chart for Logistic Regression") +

  xlab("Percentile") + ylab("Gain")













# lift chart

ggplot(data = dt_xgb3, aes(x = bucket))+

  geom_line(aes(y = Cumlift), color = "darkred") +

  #geom_abline(slope=1, intercept=0) +

  ggtitle("XGBoost") +

  xlab("Percentile") + ylab("Lift")

ggplot(data = dt_rf, aes(x = bucket))+

  geom_line(aes(y = Cumlift), color = "darkred") +

  #geom_abline(slope=1, intercept=0) +

  ggtitle("Random Forest") +

  xlab("Percentile") + ylab("Lift")

ggplot(data = dt_lr, aes(x = bucket))+

  geom_line(aes(y = Cumlift), color = "darkred") +

  #geom_abline(slope=1, intercept=0) +

  ggtitle("Logistic Regression") +

  xlab("Percentile") + ylab("Lift")




# ggplot(dt, aes(x=bucket)) +

#

#   geom_line( aes(y=Gain/10)) +

#   geom_abline(slope=1, intercept=0) +

#   #geom_line( aes(y=x)) + # Divide by 10 to get the same range than the temperature

#

#   scale_y_continuous(

#

#     # Features of the first axis

#     name = "First Axis",

#

#     # Add a second axis and specify its features

#     sec.axis = sec_axis(~.*10, name="Second Axis")

#   )

#

#

#

# ggplot(data = dt, aes(x = bucket))+

#   geom_line(aes(y = Gain/100), color = "darkred") +

#   geom_abline(slope=1, intercept=0)

#

# ggplot(data = dt, aes(x = bucket))+

#   geom_line(aes(y = Cumlift), color = "darkred")

#   #eom_abline(slope=1, intercept=0)



















# hyperparameters

################################################

# https://docs.h2o.ai/h2o/latest-stable/h2o-docs/data-science/algo-params/balance_classes.html

# GBM hyperparameters (bigger grid than above)

# Construct a large Cartesian hyper-parameter space

# ntrees_opts = c(10000)       # early stopping will stop earlier

# max_depth_opts = seq(1,20)

# min_rows_opts = c(1,5,10,20,50,100)

# learn_rate_opts = seq(0.001,0.01,0.001)

# sample_rate_opts = seq(0.3,1,0.05)

# col_sample_rate_opts = seq(0.3,1,0.05)

# col_sample_rate_per_tree_opts = seq(0.3,1,0.05)

# nbins_cats_opts = seq(100,10000,100) # no categorical features

# # in this dataset

# hyper_params = list( ntrees = ntrees_opts,

#                      max_depth = max_depth_opts,

#                      min_rows = min_rows_opts,

#                      #learn_rate = learn_rate_opts,

#                      sample_rate = sample_rate_opts,

#                      #col_sample_rate = col_sample_rate_opts,

#                      col_sample_rate_per_tree = col_sample_rate_per_tree_opts

#                      ,nbins_cats = nbins_cats_opts

# )

# search_criteria <- list(strategy = "RandomDiscrete", max_models = 36, seed = 1)

#

# # Train and validate a random grid of GBMs

# rf_grid1 <- h2o.grid("drf",

#                      x = predictors,

#                      y = response,

#                      grid_id = "rf_grid1",

#                      training_frame = train,

#                      nfolds = 5,

#                      #ntrees = 100,

#                      seed = 1,

#                      hyper_params = hyper_params,

#                      search_criteria = search_criteria)

#

# gbm_grid2 <- h2o.getGrid(grid_id = "gbm_grid2",

#                              sort_by = "auc",

#                              decreasing = TRUE)

#

# # Grab the top GBM model, chosen by validation AUC

# best_gbm2 <- h2o.getModel(gbm_gridperf2@model_ids[[1]])

#

# # Now let's evaluate the model performance on a test set

# # so we get an honest estimate of top model performance

# best_gbm_perf2 <- h2o.performance(model = best_gbm2,

#                                   newdata = test)

# h2o.auc(best_gbm_perf2)

# # 0.7810757

#

# # Look at the hyperparameters for the best model

# print(best_gbm2@model[["model_summary"]])

#

# rf_fit2 <- h2o.randomForest(x = predictors,

#                             y = response,

#                             training_frame = train,

#                             nfolds = 5,

#                             balance_classes = TRUE,

#                             seed = 1234)

#

# # AUC of cross-validated holdout predictions

# h2o.auc(rf_fit2, xval = TRUE)

#

# rf_fit2_predict <- h2o.predict(object = rf_fit2, newdata = test)

#

# h2o.head(rf_fit2_predict)

#

# # Print the coefficients table

# rf_fit2_summary <- rf_fit2@model$summary

#

# h2o.varimp_plot(rf_fit2)

# rf_fit2_varimp <- h2o.varimp(rf_fit2)

#

# rf_fit2_perf <- h2o.performance(rf_fit2, test)

# rf_fit2_perf

# #rf_fit2_perf@metrics$cm$table

#

#

# ####===========================================##########

# auc_pr_glm_fit2 <- glm_fit2_perf@metrics$pr_auc

# max_metrics_glm_fit2 <- glm_fit2_perf@metrics$max_criteria_and_metric_scores

# cm_glm_fit2 <- glm_fit2_perf@metrics$cm$table

# metrics_glm_fit2 <- glm_fit2_perf@metrics$thresholds_and_metric_scores

#

# write.xlsx(glm_fit2_summary, 'mc_modeling_h2o.xlsx',sheetName = 'glm_fit2_summary', row.names = F, append = T)

# write.xlsx(glm_fit2_varimp, 'mc_modeling_h2o.xlsx',sheetName = 'glm_fit2_varimp', row.names = F, append = T)

# write.xlsx(auc_pr_glm_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'auc_pr_glm_fit2', row.names = F, append = T)

# write.xlsx(cm_glm_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'cm_glm_fit2', row.names = F, append = T)

# write.xlsx(max_metrics_glm_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'max_metrics_glm_fit2', row.names = F, append = T)

# write.xlsx(metrics_glm_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'metrics_glm_fit2', row.names = F, append = T)

#

# auc_pr_rf_fit2 <- rf_fit2_perf@metrics$pr_auc

# max_metrics_rf_fit2 <- rf_fit2_perf@metrics$max_criteria_and_metric_scores

# cm_rf_fit2 <- rf_fit2_perf@metrics$cm$table

# metrics_rf_fit2 <- rf_fit2_perf@metrics$thresholds_and_metric_scores

#

# write.xlsx(rf_fit2_varimp, 'mc_modeling_h2o.xlsx',sheetName = 'rf_fit2_varimp', row.names = F, append = T)

# write.xlsx(auc_pr_rf_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'auc_pr_rf_fit2', row.names = F, append = T)

# write.xlsx(cm_rf_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'cm_rf_fit2', row.names = F, append = T)

# write.xlsx(max_metrics_rf_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'max_metrics_rf_fit2', row.names = F, append = T)

# write.xlsx(metrics_rf_fit2, 'mc_modeling_h2o.xlsx',sheetName = 'metrics_rf_fit2', row.names = F, append = T)




####===========================================##########

#h2osteam.stop_h2o_cluster(conn, conf)
