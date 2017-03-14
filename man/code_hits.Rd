% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/code_hits.R
\name{code_hits}
\alias{code_hits}
\title{Code hits}
\usage{
code_hits(df)
}
\arguments{
\item{df}{an raw set of pcl data}
}
\description{
\code{code_hits} imports and processes a single PCL transect.
}
\details{
this function accounts for the NAs that are in return distance which are actually
  the sky hits (i.e. when the lidar does not record a canopy hit)
}
\examples{



\dontrun{

}
}
