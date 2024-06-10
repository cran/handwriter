## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE
)

## ----setup, echo = FALSE------------------------------------------------------
library(handwriter)

## ----eval=FALSE---------------------------------------------------------------
#  template <- make_clustering_template(
#    main_dir = "path/to/main_dir",
#    template_docs = "path/to/main_dir/data/template_docs",
#    writer_indices = c(7,10),
#    centers_seed = 100,
#    K = 40,
#    num_dist_cores = 4,
#    max_iters = 25)

## -----------------------------------------------------------------------------
template <- example_cluster_template

## -----------------------------------------------------------------------------
template_data <- format_template_data(template = template)
plot_cluster_fill_counts(template_data, facet = TRUE)

## ----eval = FALSE-------------------------------------------------------------
#  model <- fit_model(main_dir = "path/to/main_dir",
#                     model_docs = "path/to/main_dir/data/model_docs",
#                     num_iters = 4000,
#                     num_chains = 1,
#                     num_cores = 2,
#                     writer_indices = c(7, 10),
#                     doc_indices = c(11, 14))

## -----------------------------------------------------------------------------
model <- example_model

## -----------------------------------------------------------------------------
plot_cluster_fill_counts(formatted_data=model, facet = TRUE)

## -----------------------------------------------------------------------------
names(as.data.frame(coda::as.mcmc(model$fitted_model[[1]])))

## -----------------------------------------------------------------------------
about_variable(variable = "mu[1,1]", model = model)

## -----------------------------------------------------------------------------
plot_trace(variable = "mu[1,1]", model = model)

## -----------------------------------------------------------------------------
model <- drop_burnin(model, burn_in = 25)

## ----eval=FALSE---------------------------------------------------------------
#  saveRDS(model, file='data/model.rds')

## ----eval = FALSE-------------------------------------------------------------
#  analysis <- analyze_questioned_documents(
#    main_dir = "path/to/main_dir",
#    questioned_docs = "path/to/main_dir/questioned_docs",
#    model = model,
#    writer_indices = c(8,11),
#    doc_indices = c(13,16),
#    num_cores = 2)

## -----------------------------------------------------------------------------
analysis <- example_analysis

## -----------------------------------------------------------------------------
plot_cluster_fill_counts(analysis, facet = TRUE)

## -----------------------------------------------------------------------------
analysis$posterior_probabilities

## -----------------------------------------------------------------------------
calculate_accuracy(analysis)

