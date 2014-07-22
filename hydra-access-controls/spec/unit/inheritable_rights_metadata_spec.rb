require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::Datastream::InheritableRightsMetadata do
  before do
    allow(Hydra).to receive(:config).and_return(
      Hydra::Config.new.tap do |config|
        config.permissions ={
          :discover => {:group =>"discover_access_group_ssim", :individual=>"discover_access_person_ssim"},
          :read => {:group =>"read_access_group_ssim", :individual=>"read_access_person_ssim"},
          :edit => {:group =>"edit_access_group_ssim", :individual=>"edit_access_person_ssim"},
          :owner => "depositor_ssim",

          :inheritable => {
            :discover => {:group =>"inheritable_discover_access_group_ssim", :individual=>"inheritable_discover_access_person_ssim"},
            :read => {:group =>"inheritable_read_access_group_ssim", :individual=>"inheritable_read_access_person_ssim"},
            :edit => {:group =>"inheritable_edit_access_group_ssim", :individual=>"inheritable_edit_access_person_ssim"},
            :owner => "inheritable_depositor_ssim"
          }
        }
        config.permissions.embargo.release_date = "embargo_release_date_dtsi"
        config.permissions.inheritable.embargo.release_date = "inheritable_embargo_release_date_dtsi"
      end
    )
  end
  
  before(:each) do
    # The way Rubydora loads objects prevents us from stubbing the fedora connection :(
    # ActiveFedora::RubydoraConnection.stubs(:instance).returns(stub_everything())
    obj = ActiveFedora::Base.new
    @sample = Hydra::Datastream::InheritableRightsMetadata.new(obj, nil)
    allow(@sample).to receive(:content).and_return('')

    @sample.permissions({:group=>"africana-faculty"}, "edit")
    @sample.permissions({:group=>"cool-kids"}, "edit")
    @sample.permissions({:group=>"slightly-cool-kids"}, "read")
    @sample.permissions({:group=>"posers"}, "discover")
    @sample.permissions({:person=>"julius_caesar"}, "edit") 
    @sample.permissions({:person=>"nero"}, "read") 
    @sample.permissions({:person=>"constantine"}, "discover") 
    @sample.embargo_release_date = "2102-10-01"
  end

  describe "to_solr" do
    subject {@sample.to_solr}
    it "should NOT provide normal solr permissions fields" do    
      expect(subject).to_not have_key( Hydra.config[:permissions][:discover][:group] ) 
      expect(subject).to_not have_key( Hydra.config[:permissions][:discover][:individual] )
      expect(subject).to_not have_key( Hydra.config[:permissions][:read][:group] )
      expect(subject).to_not have_key( Hydra.config[:permissions][:read][:individual] )
      expect(subject).to_not have_key( Hydra.config[:permissions][:edit][:group] )
      expect(subject).to_not have_key( Hydra.config[:permissions][:edit][:individual] )
      expect(subject).to_not have_key( Hydra.config[:permissions].embargo.release_date )
    end
    it "should provide prefixed/inherited solr permissions fields" do
      expect(subject[Hydra.config[:permissions][:inheritable][:discover][:group] ]).to eq ["posers"]
      expect(subject[Hydra.config[:permissions][:inheritable][:discover][:individual] ]).to eq ["constantine"]
      expect(subject[Hydra.config[:permissions][:inheritable][:read][:group] ]).to eq ["slightly-cool-kids"]
      expect(subject[Hydra.config[:permissions][:inheritable][:read][:individual] ]).to eq ["nero"]
      expect(subject[Hydra.config[:permissions][:inheritable][:edit][:group] ]).to eq ["africana-faculty", "cool-kids"]
      expect(subject[Hydra.config[:permissions][:inheritable][:edit][:individual] ]).to eq ["julius_caesar"]
      expect(subject[Hydra.config.permissions.inheritable.embargo.release_date]).to eq Date.parse("2102-10-01").to_time.utc.iso8601
    end
  end

end
