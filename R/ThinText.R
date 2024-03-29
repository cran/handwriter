# The handwriter R package performs writership analysis of handwritten documents. 
# Copyright (C) 2021 Iowa State University of Science and Technology on behalf of its Center for Statistics and Applications in Forensic Evidence
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


# EXPORTED ----------------------------------------------------------------


#' Read PNG Binary
#' 
#' This function reads in and binarizes a PNG image.
#' 
#' @param path File path for image.
#' @param cutoffAdjust Multiplicative adjustment to the K-means estimated binarization cutoff.
#' @param clean Whether to fill in white pixels with 7 or 8 neighbors. This will help a lot when thinning -- keeps from getting little white bubbles in text.
#' @param inversion Logical value dictating whether or not to flip each pixel of binarized image. Flipping happens after binarization. FALSE by default.
#' @param crop Logical value dictating whether or not to crop the white out around the image. TRUE by default. 
#' @return Returns image from path. 0 represents black, and 1 represents white by default.
#' 
#' @importFrom png readPNG
#' @useDynLib handwriter, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' 
#' @examples
#' image_path <- system.file("extdata", "phrase_example.png", package = "handwriter")
#' csafe_document <- list()
#' csafe_document$image = readPNGBinary(image_path)
#' plotImage(csafe_document)
#' 
#' @export
#' @md
readPNGBinary = function(path, cutoffAdjust = 0, clean = TRUE, crop = TRUE, inversion = FALSE)
{ mask <- NULL

  message(paste0('path in readPNGBinary: ', path))

  # TODO: magick_image not defined. Fix bug and uncomment
  # if(endsWith(path, "RData") || endsWith(path, "rda")){
  #   load(path)
  #   
  #   f <- file.path(tempdir(), "temp_png")

  #   # TODO: fix bug. magick_image not defined
  #   magick_img <- magick::image_read(magick_image)
  # 
  #   magick::image_write(magick_img, path = f, format = "png")
  #   img = png::readPNG(f)
  #   
  # }else{
  
  img = png::readPNG(path)
    
  # }
  
  img = as.array(img)
  
  #Want only a grayscale image - so if more than 2 dimensions (Grayscale Alpha, RGB, or RGB Alpha)... reduce
  if(length(dim(img)) > 2)
  {
    #If there are 4 channels (RGB-Alpha) reduce to 3 (RGB)
    if(dim(img)[3] == 4)
    {
      img = rgba2rgb(img)
    }
    #If there is more than 1 channel (RGB or Grayscale Alpha) reduce to Grayscale
    if(dim(img)[3] > 1)
    {
      img = rgb2grayscale(img)
    }
  }
  if(inversion)
    img = 1-img
  
  # Threshold Image
  # Otsu's Method (https://en.wikipedia.org/wiki/Otsu%27s_method) is used to return an intensity threshold,
  # which separates the image into foreground and background
  thresh = otsuBinarization(img, 512)
  
  #Adjust the threshhold for cutoffAdjust parameter
  if(cutoffAdjust > 0) thresh = thresh*(1-cutoffAdjust) + cutoffAdjust
  else if(cutoffAdjust < 0) thresh = thresh*(1+cutoffAdjust)
  
  #Turn the grayscale image to just black and white
  img = img > thresh
  
  #ADD MASK
  
  #convert numeric mask to logical
  if(exists('mask') && !is.null(mask)){
    logical_mask <- as.logical(mask) & ( as.integer(mask) > 0 )
    logical_mask[is.na(mask)] <- TRUE
    dim(logical_mask) <- dim(mask)
    
    img[which(logical_mask == TRUE)] <- TRUE
  }
  
  #if clean param is True, cleanBinaryImage removes the alpha parameter from the image.
  #NOTE: I thought the alpha parameter was removed above but it appears this will double check?
  if(clean)
  {
    img = cleanBinaryImage(img)
  }
  
  #crops the white out (except a 1 pixel padding) around the image
  if(crop)
  {
    img = crop(img)
  }
  return(img + 0)
}

# Internal Functions ------------------------------------------------------


#' otsuBinarization
#' 
#' Uses Otsu's Method to binarize given image, performing automatic image thresholding. 
#' 
#' @param img image object to be processed
#' @param breaks a single number giving the number of cells for the histogram
#' 
#' @return separated image into foreground and background
#' @noRd
otsuBinarization = function(img, breaks = 512)
{
  histVals = hist(img, breaks = breaks, plot = FALSE)
  numBins = length(histVals$counts)
  w1 = cumsum(histVals$counts)
  w2 = w1[numBins] + histVals$counts - w1
  mu1 = cumsum(histVals$counts*histVals$mids)
  mu2 = mu1[numBins] + histVals$counts*histVals$mids - mu1
  var = log(w1) + log(w2) + 2*log((mu2/w2 - mu1/w1))
  peak = which.max(var)

  return(histVals$mids[peak])
}

#' Crop
#'
#' This function crops an image down so that there is 1 pixel of padding on each side of the outermost 0 points.
#' 
#' @param img Full image matrix to be cropped
#' @return Cropped image matrix.
#' @noRd
crop = function(img)
{
  if(any(img[,1] != 1)) {img = cbind(rep(1, dim(img)[1]), img)}
  if(any(img[,dim(img)[2]] != 1)) {img = cbind(img, rep(1, dim(img)[1]))}
  if(any(img[1,] != 1)) {img = rbind(rep(1, dim(img)[2]), img)}
  if(any(img[dim(img)[1],] != 1)) {img = rbind(img, rep(1, dim(img)[2]))}

  rows = apply(img, 1, FUN = function(x){any(x != 1)})
  cols = apply(img, 2, FUN = function(x){any(x != 1)})
  x.min = max(which(rows)[1] - 1, 1)
  x.max = min(which(rows)[sum(rows)] + 1, length(rows))
  y.min = max(which(cols)[1] - 1, 1)
  y.max = min(which(cols)[sum(cols)] + 1, length(cols))

  return(img[x.min:x.max,y.min:y.max])
}
