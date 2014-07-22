require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::Datastream::RightsMetadata do

  let(:parent) { double('inner object', uri: '/fedora/rest/test/1234', id: '1234', new_record?: true) }

  let(:sample) { Hydra::Datastream::RightsMetadata.new(parent, 'rightsMetadata') }
  
  describe "license" do
    before do
      sample.license.title = "Creative Commons Attribution 3.0 Unported License." 
      sample.license.description = "This Creative Commons license lets others distribute, remix, tweak, and build upon your work, even commercially, as long as they credit you for the original creation. This is the most accommodating of licenses offered. Recommended for maximum dissemination and use of licensed materials." 
      sample.license.url = "http://creativecommons.org/licenses/by/3.0/" 
    end
    subject { sample.license}
    its(:title) {should == ["Creative Commons Attribution 3.0 Unported License."] }
    its(:description) { should == ["This Creative Commons license lets others distribute, remix, tweak, and build upon your work, even commercially, as long as they credit you for the original creation. This is the most accommodating of licenses offered. Recommended for maximum dissemination and use of licensed materials."] }
    its(:url) {should == ["http://creativecommons.org/licenses/by/3.0/"] }

    it "should be accessable as a term path" do
      # This enables us to use:
      #  delegate :license_title, :to=>'rightsMetadata', :at=>[:license, :title]
      expect(sample.term_values(:license, :title)).to eq ["Creative Commons Attribution 3.0 Unported License."]
    end
  end
  
  describe "permissions" do
    describe "setter" do
      it "should set person permissions" do
        sample.permissions = {"person"=>{"maria"=>"read","marcus"=>"discover"}}
      end
      it "should set group permissions" do
        sample.permissions = {"group"=>{"librarians"=>"read","students"=>"discover"}}
      end
      it "should create/update/delete permissions for the given user/group" do
        expect(sample.class.terminology.xpath_for(:access, :person, "person_123")).to eq '//oxns:access/oxns:machine/oxns:person[contains(., "person_123")]'
        
        person_123_perms_xpath = sample.class.terminology.xpath_for(:access, :person, "person_123")
        group_zzz_perms_xpath = sample.class.terminology.xpath_for(:access, :group, "group_zzz")
        
        expect(sample.find_by_terms(person_123_perms_xpath)).to be_empty 
        expect(sample.permissions({"person"=>"person_123"}, "edit")).to eq "edit"
        expect(sample.permissions({"group"=>"group_zzz"}, "edit")).to eq "edit"      
        
        expect(sample.find_by_terms(person_123_perms_xpath).first.ancestors("access").first.attributes["type"].text).to eq "edit"
        expect(sample.find_by_terms(group_zzz_perms_xpath).first.ancestors("access").first.attributes["type"].text).to eq "edit"
        
        sample.permissions({"person"=>"person_123"}, "read")
        sample.permissions({"group"=>"group_zzz"}, "read")
        expect(sample.find_by_terms(person_123_perms_xpath).length).to eq 1
        
        expect(sample.find_by_terms(person_123_perms_xpath).first.ancestors("access").first.attributes["type"].text).to eq "read"
        expect(sample.find_by_terms(group_zzz_perms_xpath).first.ancestors("access").first.attributes["type"].text).to eq "read"
      
        expect(sample.permissions({"person"=>"person_123"}, "none")).to eq "none"
        expect(sample.permissions({"group"=>"group_zzz"}, "none")).to eq "none"
        expect(sample.find_by_terms(person_123_perms_xpath)).to  be_empty 
        expect(sample.find_by_terms(person_123_perms_xpath)).to be_empty 
      end
      it "should remove existing permissions (leaving only one permission level per user/group)" do
        person_123_perms_xpath = sample.class.terminology.xpath_for(:access, :person, "person_123")
        group_zzz_perms_xpath = sample.class.terminology.xpath_for(:access, :group, "group_zzz")
                        
        expect(sample.find_by_terms(person_123_perms_xpath).length).to eq 0
        expect(sample.find_by_terms(group_zzz_perms_xpath).length).to eq 0
        sample.permissions({"person"=>"person_123"}, "read")
        sample.permissions({"group"=>"group_zzz"}, "read")
        expect(sample.find_by_terms(person_123_perms_xpath).length).to eq 1
        expect(sample.find_by_terms(group_zzz_perms_xpath).length).to eq 1
        
        sample.permissions({"person"=>"person_123"}, "edit")
        sample.permissions({"group"=>"group_zzz"}, "edit")
        expect(sample.find_by_terms(person_123_perms_xpath).length).to eq 1
        expect(sample.find_by_terms(group_zzz_perms_xpath).length).to eq 1
      end
      it "should not impact other users permissions" do
        sample.permissions({"person"=>"person_123"}, "read")
        sample.permissions({"person"=>"person_789"}, "edit")
        
        expect(sample.permissions({"person"=>"person_123"})).to eq "read"
        sample.permissions({"person"=>"person_456"}, "read")
        expect(sample.permissions({"person"=>"person_123"})).to eq "read"
        expect(sample.permissions({"person"=>"person_456"})).to eq "read"
        expect(sample.permissions({"person"=>"person_789"})).to eq "edit"
        
        
      end
    end
    describe "getter" do
      it "should return permissions level for the given user/group" do
        sample.permissions({"person"=>"person_123"}, "edit")
        sample.permissions({"group"=>"group_zzz"}, "discover")
        expect(sample.permissions({"person"=>"person_123"})).to eq "edit"
        expect(sample.permissions({"group"=>"group_zzz"})).to eq "discover"
        expect(sample.permissions({"group"=>"foo_people"})).to eq "none"
      end
    end
  end
  describe "groups" do
    it "should return a hash of all groups with permissions set, along with their permission levels" do
      sample.permissions({"group"=>"group_zzz"}, "edit")
      sample.permissions({"group"=>"public"}, "discover")

      expect(sample.groups).to eq("public"=>"discover", "group_zzz"=>"edit")
    end
  end
  describe "individuals" do
    it "should return a hash of all individuals with permissions set, along with their permission levels" do
      sample.permissions({"person"=>"person_123"}, "read")
      sample.permissions({"person"=>"person_456"}, "edit")
      expect(sample.users).to eq("person_123"=>"read", "person_456"=>"edit")
    end
  end
  
  describe "update_permissions" do
    it "should accept a hash of groups and persons, updating their permissions accordingly" do
      expect(sample).to receive(:permissions).with({"group" => "group1"}, "discover")
      expect(sample).to receive(:permissions).with({"group" => "group2"}, "edit")
      expect(sample).to receive(:permissions).with({"person" => "person1"}, "read")
      expect(sample).to receive(:permissions).with({"person" => "person2"}, "discover")
      
      sample.update_permissions( {"group"=>{"group1"=>"discover","group2"=>"edit"}, "person"=>{"person1"=>"read","person2"=>"discover"}} )
    end
  end

  describe "clear_permissions!" do
    before do
      sample.permissions({"person"=>"person_123"}, "read")
      sample.permissions({"person"=>"person_456"}, "edit")
      sample.permissions({"person"=>"person_789"}, "discover")
      sample.permissions({"group"=>"group_123"}, "read")
      sample.permissions({"group"=>"group_456"}, "edit")
      sample.permissions({"group"=>"group_789"}, "discover")
    end
    it "clears permissions" do
      sample.clear_permissions!
      expect(sample.users).to eq({})
      expect(sample.groups).to eq({})
    end
  end
  
  describe "to_solr" do
    it "should populate solr doc with the correct fields" do
      params = {[:edit_access, :person]=>"Lil Kim", [:edit_access, :group]=>["group1","group2"], [:discover_access, :group]=>["public"],[:discover_access, :person]=>["Joe Schmoe"]}
      sample.update_values(params)
      solr_doc = sample.to_solr
      
      expect(solr_doc["edit_access_person_ssim"]).to eq ["Lil Kim"]
      expect(solr_doc["edit_access_group_ssim"].sort).to eq ["group1", "group2"]
      expect(solr_doc["discover_access_person_ssim"]).to eq ["Joe Schmoe"]
      expect(solr_doc["discover_access_group_ssim"]).to eq ["public"]
    end
    it "should solrize fixture content correctly" do
      lsample = Hydra::Datastream::RightsMetadata.new(ActiveFedora::Base.new, nil)
      lsample.update_permissions({'person' => {'researcher1' => 'edit'},
                                  'group' => {'archivist' => 'edit', 'public' =>'read', 'bob'=>'discover'}})

      solr_doc = lsample.to_solr
      expect(solr_doc["edit_access_person_ssim"]).to eq ["researcher1"]
      expect(solr_doc["edit_access_group_ssim"]).to eq ["archivist"]
      expect(solr_doc["read_access_group_ssim"]).to eq ["public"]
      expect(solr_doc["discover_access_group_ssim"]).to eq ["bob"]
    end

    it "should solrize embargo information if set" do
      sample.embargo_release_date = DateTime.parse("2010-12-01T23:59:59+0")
      solr_doc = sample.to_solr
      expect(solr_doc["embargo_release_date_dtsi"]).to eq "2010-12-01T23:59:59Z"
    end

    it "should solrize lease information if set" do
      sample.lease_expiration_date = DateTime.parse("2010-12-01T23:59:59Z")
      solr_doc = sample.to_solr
      expect(solr_doc["lease_expiration_date_dtsi"]).to eq "2010-12-01T23:59:59Z"
    end
  end

  describe "embargo" do
    describe "embargo_release_date=" do
      it "should update the appropriate node with the value passed" do
        sample.embargo_release_date = Date.parse("2010-12-01")
        expect(sample.embargo_release_date).to eq [Date.parse("2010-12-01").to_time.utc]
      end

      it "should accept a nil value after having a date value" do
        sample.embargo_release_date = Date.parse("2010-12-01")
        sample.embargo_release_date = nil
        expect(sample.embargo_release_date).to be_empty
      end
    end

    describe "embargo_release_date" do
      it "should return solr formatted date" do
        sample.embargo_release_date = DateTime.parse("2010-12-01T23:59:59Z")
        expect(sample.embargo_release_date).to eq [DateTime.parse("2010-12-01T23:59:59Z")]
      end
    end

    describe "under_embargo?" do
      it "should return true if the current date is before the embargo release date" do
        sample.embargo_release_date=Date.today+1.month
        expect(sample).to be_under_embargo
      end

      it "should return false if the current date is after the embargo release date" do
        sample.embargo_release_date=Date.today-1.month
        expect(sample).to_not be_under_embargo
      end

      it "should return false if there is no embargo date" do
        sample.embargo_release_date = nil
        expect(sample).to_not be_under_embargo
      end
    end

    describe "visibility during/after embargo" do
      it "should track visibility values and index them into solr" do
        expect(sample.visibility_during_embargo).to be_empty
        expect(sample.visibility_after_embargo).to be_empty
        sample.visibility_during_embargo = "private"
        sample.visibility_after_embargo = "restricted"
        expect(sample.visibility_during_embargo).to eq ["private"]
        expect(sample.visibility_after_embargo).to eq ["restricted"]
        solr_doc = sample.to_solr
        expect(solr_doc["visibility_during_embargo_ssim"]).to eq ["private"]
        expect(solr_doc["visibility_after_embargo_ssim"]).to eq ["restricted"]
      end

      it "has the correct xpath" do
        expect(sample.visibility_during_embargo.xpath).to eq "//oxns:embargo/oxns:machine/oxns:visibility[@scope=\"during\"]"
        expect(sample.visibility_after_embargo.xpath).to eq "//oxns:embargo/oxns:machine/oxns:visibility[@scope=\"after\"]"
      end
    end

    describe 'embargo_history' do
      subject { sample.embargo_history }
      it "has the correct xpath" do
        expect(subject.xpath).to eq '//oxns:embargo/oxns:human'
      end
    end
  end

  describe "leases" do

    describe "lease_expiration_date=" do
      it "should update the appropriate node with the value passed" do
        sample.lease_expiration_date = "2010-12-01"
        expect(sample.lease_expiration_date).to eq [Date.parse("2010-12-01").to_time.utc]
      end
      it "should only accept valid date values" do

      end
      it "should accept a nil value after having a date value" do
        sample.lease_expiration_date = "2010-12-01"
        sample.lease_expiration_date = nil
        expect(sample.lease_expiration_date).to be_empty
      end
    end

    describe "active_lease?" do
      it "should return true if the current date is after the lease expiration date" do
        sample.lease_expiration_date = Date.today-1.month
        expect(sample).to_not be_active_lease
      end
      it "should return false if the current date is before the lease expiration date" do
        sample.lease_expiration_date = Date.today+1.month
        expect(sample).to be_active_lease
      end
      it "should return false if there is no lease expiration date" do
        sample.lease_expiration_date = nil
        expect(sample).to_not be_active_lease
      end
    end

    describe "visibility during/after lease" do
      it "should track visibility values and index them into solr" do
        expect(sample.visibility_during_lease).to be_empty
        expect(sample.visibility_after_lease).to be_empty
        sample.visibility_during_lease = "restricted"
        sample.visibility_after_lease = "private"
        expect(sample.visibility_during_lease).to eq ["restricted"]
        expect(sample.visibility_after_lease).to eq ["private"]
        solr_doc = sample.to_solr
        expect(solr_doc["visibility_during_lease_ssim"]).to eq ["restricted"]
        expect(solr_doc["visibility_after_lease_ssim"]).to eq ["private"]
      end

      it "has the correct xpath" do
        expect(sample.visibility_during_lease.xpath).to eq "//oxns:lease/oxns:machine/oxns:visibility[@scope=\"during\"]"
        expect(sample.visibility_after_lease.xpath).to eq "//oxns:lease/oxns:machine/oxns:visibility[@scope=\"after\"]"
      end
    end

    describe 'lease_history' do
      subject { sample.lease_history }
      it "has the correct xpath" do
        expect(subject.xpath).to eq '//oxns:lease/oxns:human'
      end
    end
  end
end
