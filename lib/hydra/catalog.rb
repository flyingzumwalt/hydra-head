require "hydra/access_controls_enforcement"
# Include this module into any of your Blacklight Catalog classes (ie. CatalogController) to add Hydra functionality
#
# The primary function of this module is to mix in a number of other Hydra Modules, including 
#   Hydra::AccessControlsEnforcement
#
# This module will only work if you also include Blacklight::Catalog in the Controller you're extending.
# The hydra head rails generator will create the CatalogController for you in app/controllers/catalog_controller.rb
# @example 
#  require 'blacklight/catalog'
#  require 'hydra/catalog'
#  class CustomCatalogController < ApplicationController  
#    include Blacklight::Catalog
#    include Hydra::Catalog
#  end
module Hydra::Catalog
  
  def self.included(klass)
    # Other modules to auto-include
    klass.send(:include, Hydra::AccessControlsEnforcement)
    
    # Controller filters
    # Also see the generator (or generated CatalogController) to see more before_filters in action
    klass.before_filter :load_fedora_document, :only=>[:show,:edit]
    klass.before_filter :lookup_facets, :only=>:edit
  end
  
  def edit
    show
  end
  
  def load_fedora_document
    af_base = ActiveFedora::Base.load_instance(params[:id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil?
      @document_fedora = af_base
    else
      @document_fedora = the_model.load_instance(params[:id])
    end
    @file_assets = @document_fedora.file_objects(:response_format=>:solr)
  end
  
  def lookup_facets
    params = {:qt=>"search",:defType=>"dismax",:q=>"*:*",:rows=>"0",:facet=>"true", :facets=>{:fields=>Blacklight.config[:facet][:field_names]}}
    @facet_lookup = Blacklight.solr.find params
  end
end