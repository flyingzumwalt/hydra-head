# Include this module into any of your Controller classes to add Hydra functionality
#
# The primary function of this module is to mix in a number of other Hydra Modules, including 
#   Hydra::AccessControlsEnforcement
#
# @example 
#  class CustomHydraController < ApplicationController  
#    include Hydra::Controller
#  end
#
# will move to lib/hydra/controller/controller_behavior in release 5.x
require 'deprecation'
module Hydra::Controller::ControllerBehavior
  extend ActiveSupport::Concern
  extend Deprecation
  self.deprecation_horizon = 'hydra-head 5.x'

  included do
    # Other modules to auto-include
    include Hydra::AccessControlsEnforcement
    include Hydra::Controller::RepositoryControllerBehavior
  
    helper :hydra
    helper :hydra_assets

    # Catch permission errors
    rescue_from Hydra::AccessDenied do |exception|
      if (exception.action == :edit)
        redirect_to({:action=>'show'}, :alert => exception.message)
      elsif current_user and current_user.persisted?
        redirect_to root_url, :alert => exception.message
      else
        session["user_return_to"] = request.url
        redirect_to new_user_session_url, :alert => exception.message
      end
    end
  end
  
  # Use params[:id] to load an object from Fedora.  Inspects the object for known models and mixes in any of those models' behaviors.
  # Sets @document_fedora with the loaded object
  # Sets @file_assets with file objects that are children of the loaded object
  def load_fedora_document
    @document_fedora = ActiveFedora::Base.find(params[:id], :cast=>true)
    unless @document_fedora.class.include?(Hydra::ModelMethods)
      @document_fedora.class.send :include, Hydra::ModelMethods
    end
    
    @file_assets = @document_fedora.parts(:response_format=>:solr)
  end
  deprecation_deprecate :load_fedora_document
  
  
  # get the currently configured user identifier.  Can be overridden to return whatever (ie. login, email, etc)
  # defaults to using whatever you have set as the Devise authentication_key
  def user_key
    current_user.user_key if current_user
  end
  
end