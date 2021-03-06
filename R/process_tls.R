#' Process single PCL transects.
#'
#' \code{process_tls} imports and processes a slice from a voxelated TLS scan.
#'
#' This function takes as input a four column .CSV file or data frame of x, y, z, and VAI
#' (Vegetation Area Index) derived from 3-D (TLS) LiDAR data. Currently, this function only
#'  analyzes a single slice from the inputed TLS data set. VAI is calculated externally
#'  by the user using user-determined methodology.
#'
#' The \code{process_tls} function will write multiple output files to disk in an (output)
#' directory that \code{process_tls} creates within the work directing. These files include:
#'
#' 1. an output variables file that contains a list of CSC variables and is
#' written by the subfunction \code{write_pcl_to_csv}
#'
#' 2. a summary matrix, that includes detailed information on each vertical column of Lidar data
#' written by the subfunction \code{write_summary_matrix_to_csv}
#'
#' 3. a hit matrix, which is a matrix of VAI at each x and z position, written by the
#' subfunction \code{write_hit_matrix_to_pcl}
#'
#' 4. a hit grid, which is a graphical representation of VAI along the x and z coordinate space.
#' 5. optionally, plant area/volume density profiles can be created by including
#' \code{pavd = TRUE} that include an additional histogram with the optional \code{hist = TRUE} in the
#' \code{process_pcl} call.
#'
#' @param f  the name of the filename to input <character> or a data frame <data frame>.
#' @param pavd logical input to include Plant Area Volume Density Plot from \code{plot_pavd}, if TRUE it is included, if FALSE, it is not.
#' @param hist logical input to include histogram of VAI with PAVD plot, if TRUE it is included, if FALSE, it is not.
#' @param slice the number of the transect to use from xyz tls data
#' @param save_output needs to be set to true, or else you are just going to get a lot of data on the screen
#'
#' @return writes the hit matrix, summary matrix, and output variables
#' to csv in an output folder, along with hit grid plot
#'
#' @keywords tls processing
#'
#' @export
#'
#' @seealso
#' \code{\link{process_pcl}}
#'
#' @examples
#'
#' # with designated file
#' uva.tls<- system.file("extdata", "UVAX_A4_01_tls.csv", package = "forestr")
#'
#' process_tls(uva.tls, slice = 5, pavd = FALSE, hist = FALSE, save_output = FALSE)
#'
#'

process_tls<- function(f, slice, pavd = FALSE, hist = FALSE, save_output = TRUE){
  xbin <- NULL
  zbin <- NULL
  vai <- NULL
  x <- NULL
  m5 <- NULL


  if(is.character(f) == TRUE) {

    # Read in TLS
    df.xyz <- utils::read.csv(f, header = FALSE, col.names = c("x", "y", "z", "vai"), blank.lines.skip = FALSE)

  # Cuts off the directory info to give just the filename.
    filename <- sub(".*/", "", f)

  } else if(is.data.frame(f) == TRUE){
    df.xyz <- f
    filename <- deparse(substitute(f))
  } else {
    warning('This is not the data you are looking for')
  }

  # If output directory name is missing, add it.
  if(missing(save_output)){
    save_output == TRUE
    output_dir = 'output'
  }

  # Data munging TLS df to PCL style slice

  # this selects the east most transect
  df <- dplyr::filter(df.xyz, x == slice)

  # renaming columns. The y value gets renamed xbin because it is now a transect
  m1 <- plyr::rename(df, c( "y" = "xbin", "z" = "zbin", "vai" = "vai"))

  # derive tls mean leaf height
  m2 <- calc_tls_mean_leaf_ht(m1)

  variable.list <- calc_tls_csc(m2, filename)

  output.variables  <- cbind(variable.list)


  transect.length <- max(m2$xbin)





  vai.label =  expression(paste(VAI~(m^2 ~m^-2)))


  #setting up hit grid
  m6 <- m2
  m6$vai[m6$vai == 0] <- NA

  #x11(width = 8, height = 6)
  hit.grid <- ggplot2::ggplot(m6, ggplot2::aes(x = xbin, y = zbin))+
    ggplot2::geom_tile(ggplot2::aes(fill = vai))+
    ggplot2::scale_fill_gradient(low="gray88", high="dark green",
                                 na.value = "white",
                                 limits=c(0, 8),
                                 name=vai.label)+
    #scale_y_continuous(breaks = seq(0, 20, 5))+
    # scale_x_continuous(minor_breaks = seq(0, 40, 1))+
    ggplot2::theme(axis.line = ggplot2::element_line(colour = "black"),
                   panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_blank(),
                   axis.text.x = ggplot2::element_text(size = 14),
                   axis.text.y = ggplot2::element_text(size = 14),
                   axis.title.x = ggplot2::element_text(size = 20),
                   axis.title.y = ggplot2::element_text(size = 20))+
    ggplot2::xlim(0,transect.length)+
    ggplot2::ylim(0,41)+
    ggplot2::xlab("Distance along transect (m)")+
    ggplot2::ylab("Height above ground (m)")+
    ggplot2::ggtitle(filename)+
    ggplot2::theme(plot.title = ggplot2::element_text(lineheight=.8, face="bold"))


  # PAVD
  if(pavd == TRUE && hist == FALSE){

    plot_pavd(m2, filename, plot.file.path.pavd)
  }
  if(pavd == TRUE && hist == TRUE){

    plot_pavd(m2, filename, plot.file.path.pavd, hist = TRUE)
  }




if(save_output == TRUE){
  #output procedure for variables
  outputname = substr(filename,1,nchar(filename)-4)
  outputname <- paste(outputname, "output", sep = "_")
  dir.create("output", showWarnings = FALSE)
  output_directory <- "./output/"
  print(outputname)
  print(output_directory)


  #get filename first
  plot.filename <- tools::file_path_sans_ext(filename)
  plot.filename.full <- paste(plot.filename, "hit_grid", sep = "_")
  plot.filename.pavd <- paste(plot.filename, "pavd", sep = "_")

  plot.file.path.hg <- file.path(paste(output_directory, plot.filename.full, ".png", sep = ""))
  plot.file.path.pavd <- file.path(paste(output_directory, plot.filename.pavd, ".png", sep = ""))

  write_pcl_to_csv(output.variables, outputname, output_directory)
  write_summary_matrix_to_csv(summary.matrix, outputname, output_directory)
  write_hit_matrix_to_csv(m5, outputname, output_directory)

  ggplot2::ggsave(plot.file.path.hg, hit.grid, width = 8, height = 6, units = c("in"))

}
}
