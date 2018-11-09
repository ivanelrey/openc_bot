# encoding: UTF-8
require_relative '../../spec_helper'
require 'openc_bot'
require 'openc_bot/helpers/register_methods'

module ModuleThatIncludesRegisterMethods
  extend OpencBot
  extend OpencBot::Helpers::RegisterMethods
  PRIMARY_KEY_NAME = :custom_uid
  SCHEMA_NAME = 'company-schema'
  SLEEP_BEFORE_HTTP_REQ = 2
  RAISE_WHEN_SAVING_INVALID_RECORD = true
end

module ModuleWithNoCustomPrimaryKey
  extend OpencBot
  extend OpencBot::Helpers::RegisterMethods
  SAVE_RAW_DATA_ON_FILESYSTEM = true
end

describe 'a module that includes RegisterMethods' do

  before do
    allow(ModuleThatIncludesRegisterMethods).to receive(:sqlite_magic_connection).
                                      and_return(test_database_connection)
  end

  after do
    remove_test_database
  end

  describe "#datum_exists?" do
    before do
      allow(ModuleThatIncludesRegisterMethods).to receive(:select).and_return([])
    end

    it "should select_data from database" do
      expected_sql_query = "ocdata.custom_uid FROM ocdata WHERE custom_uid = ? LIMIT 1"
      expect(ModuleThatIncludesRegisterMethods).to receive(:select).with(expected_sql_query, '4567').and_return([])
      ModuleThatIncludesRegisterMethods.datum_exists?('4567')
    end

    it "should return true if result returned" do
      allow(ModuleThatIncludesRegisterMethods).to receive(:select).and_return([{'custom_uid' => '4567'}])

      expect(ModuleThatIncludesRegisterMethods.datum_exists?('4567')).to be true
    end

    it "should return false if result returned" do
      expect(ModuleThatIncludesRegisterMethods.datum_exists?('4567')).to be false
    end
  end

  describe "#export_data" do
    before do
      allow(ModuleThatIncludesRegisterMethods).to receive(:select).and_return([])

    end

    it "should select_data from database" do
      expected_sql_query = "ocdata.* from ocdata"
      expect(ModuleThatIncludesRegisterMethods).to receive(:select).with(expected_sql_query).and_return([])
      ModuleThatIncludesRegisterMethods.export_data
    end

    it "should yield rows that have been passed to post_process" do
      datum = {'food' => 'tofu'}
      allow(ModuleThatIncludesRegisterMethods).to receive(:select).and_return([datum])
      expect(ModuleThatIncludesRegisterMethods).to receive(:post_process).with(datum, true).and_return(datum)
      ModuleThatIncludesRegisterMethods.export_data{|x|}
    end
  end


  describe '#primary_key_name' do
    it 'should return :uid if PRIMARY_KEY_NAME not set' do
      expect(ModuleWithNoCustomPrimaryKey.send(:primary_key_name)).to eq(:uid)
    end

    it 'should return value if PRIMARY_KEY_NAME set' do
      expect(ModuleThatIncludesRegisterMethods.send(:primary_key_name)).to eq(:custom_uid)
    end
  end

  describe "#use_alpha_search" do
    context 'and no USE_ALPHA_SEARCH constant' do
      it "should not return true" do
        expect(ModuleThatIncludesRegisterMethods.use_alpha_search).not_to be true
      end
    end

    context 'and USE_ALPHA_SEARCH constant set' do
      it "should return USE_ALPHA_SEARCH" do
        stub_const("ModuleThatIncludesRegisterMethods::USE_ALPHA_SEARCH", true)
        expect(ModuleThatIncludesRegisterMethods.use_alpha_search).to be true
      end
    end
  end

  describe "#schema_name" do
    context 'and no SCHEMA_NAME constant' do
      it "should return nil" do
        expect(ModuleWithNoCustomPrimaryKey.schema_name).to be_nil
      end
    end

    context 'and SCHEMA_NAME constant set' do
      it "should return SCHEMA_NAME" do
        expect(ModuleThatIncludesRegisterMethods.schema_name).to eq('company-schema')
      end
    end
  end

  describe "#update_data" do
    before do
      allow(ModuleThatIncludesRegisterMethods).to receive(:fetch_data_via_incremental_search)
      allow(ModuleThatIncludesRegisterMethods).to receive(:update_stale)
    end

    it "should get new records via incremental search" do
      expect(ModuleThatIncludesRegisterMethods).not_to receive(:fetch_data_via_alpha_search)
      expect(ModuleThatIncludesRegisterMethods).to receive(:fetch_data_via_incremental_search)
      ModuleThatIncludesRegisterMethods.update_data
    end

    it "should get new records via alpha search if use_alpha_search" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:use_alpha_search).and_return(true)
      expect(ModuleThatIncludesRegisterMethods).not_to receive(:fetch_data_via_incremental_search)
      expect(ModuleThatIncludesRegisterMethods).to receive(:fetch_data_via_alpha_search)
      ModuleThatIncludesRegisterMethods.update_data
    end

    it "should update stale records" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:update_stale)
      ModuleThatIncludesRegisterMethods.update_data
    end

    it "should save run report" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:save_run_report).with(:status => 'success')
      ModuleThatIncludesRegisterMethods.update_data
    end

    it "should not raise error if passed options" do
      expect { ModuleThatIncludesRegisterMethods.update_data }.not_to raise_error
    end
  end

  describe "#update_stale" do
    it "should get uids of stale entries" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:stale_entry_uids)
      ModuleThatIncludesRegisterMethods.update_stale
    end

    it "should update_datum for each entry yielded by stale_entries" do
      allow(ModuleThatIncludesRegisterMethods).to receive(:stale_entry_uids).and_yield('234').and_yield('666').and_yield('876')
      expect(ModuleThatIncludesRegisterMethods).to receive(:update_datum).with('234')
      expect(ModuleThatIncludesRegisterMethods).to receive(:update_datum).with('666')
      expect(ModuleThatIncludesRegisterMethods).to receive(:update_datum).with('876')
      ModuleThatIncludesRegisterMethods.update_stale
    end

    context "and limit passed in" do
      it "should pass on limit to #stale_entries" do
        expect(ModuleThatIncludesRegisterMethods).to receive(:stale_entry_uids).with(42)
        ModuleThatIncludesRegisterMethods.update_stale(42)
      end
    end

    it 'should return number of entries updated' do
      allow(ModuleThatIncludesRegisterMethods).to receive(:stale_entry_uids).and_yield('234').and_yield('666').and_yield('876')
      allow(ModuleThatIncludesRegisterMethods).to receive(:update_datum)
      expect(ModuleThatIncludesRegisterMethods.update_stale).to eq({:updated => 3})
    end

    context 'and OutOfPermittedHours raised' do
      before do
        @exception = OpencBot::OutOfPermittedHours.new('not supposed to be running')
      end

      it 'should return number updated and exception message' do
        allow(ModuleThatIncludesRegisterMethods).to receive(:stale_entry_uids).
          and_yield('234').
          and_yield('666').
          and_raise(@exception)
        allow(ModuleThatIncludesRegisterMethods).to receive(:update_datum)
        expect(ModuleThatIncludesRegisterMethods.update_stale).to eq({ :updated => 2, :output => @exception.message })
      end
    end

    context 'and SourceClosedForMaintenance raised' do
      before do
        @exception = OpencBot::SourceClosedForMaintenance.new('site is down')
      end

      it 'should return number updated and exception message' do
        allow(ModuleThatIncludesRegisterMethods).to receive(:stale_entry_uids).
          and_yield('234').
          and_yield('666').
          and_raise(@exception)
        allow(ModuleThatIncludesRegisterMethods).to receive(:update_datum)
        expect(ModuleThatIncludesRegisterMethods.update_stale).to eq({ :updated => 2, :output => @exception.message })
      end
    end
  end

  describe "#stale_entry_uids" do
    before do
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => '99999')
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => 'A094567')
    end

    it "should get entries which have not been retrieved or are more than 1 month old, oldest first" do
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => '5234888', :retrieved_at => (Date.today-40).to_time)
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => '87654', :retrieved_at => (Date.today-50)) # date, not time.
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => '9234567', :retrieved_at => (Date.today-2).to_time) # not stale

      expect {|b| ModuleThatIncludesRegisterMethods.stale_entry_uids(&b)}.to yield_successive_args('99999', 'A094567', '87654', '5234888')
    end

    context "and no retrieved_at column" do
      it "should not raise error" do
        expect { ModuleThatIncludesRegisterMethods.stale_entry_uids {} }.not_to raise_error
      end

      it "should create retrieved_at column" do
        ModuleThatIncludesRegisterMethods.stale_entry_uids {}
        expect(ModuleThatIncludesRegisterMethods.select('* from ocdata').first.keys).to include('retrieved_at')
      end

      it "should retry" do
        expect {|b| ModuleThatIncludesRegisterMethods.stale_entry_uids(&b)}.to yield_successive_args('99999','A094567')
      end
    end
  end

  describe 'stale_entry?' do

    it "should return true if entry is older than stale date" do
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => '5234888', :retrieved_at => (Date.today-40).to_time)
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => '9234567', :retrieved_at => (Date.today-2).to_time)
      expect(ModuleThatIncludesRegisterMethods.stale_entry?('5234888')).to eq(true)
      expect(ModuleThatIncludesRegisterMethods.stale_entry?('9234567')).to eq(false)
    end

    it 'should return true if ocdata table doesnt exist' do
      expect(ModuleThatIncludesRegisterMethods.stale_entry?('foo')).to eq(true)
    end

    it 'should return true if record doesnt exist' do
      ModuleThatIncludesRegisterMethods.save_data([:custom_uid], :custom_uid => '5234888', :retrieved_at => (Date.today-2).to_time) # note: this creates the ocdata table, otherwise we get true returned because that's behaviour for such situations
      expect(ModuleThatIncludesRegisterMethods.stale_entry?('foo')).to eq(true)
    end

  end

  describe '#prepare_and_save_data' do
    before do
      @params = {:name => 'Foo Inc', :custom_uid => '12345', :foo => ['bar','baz'], :foo2 => {:bar => 'baz'}}
    end

    it "should insert_or_update data using primary_key" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:insert_or_update).with([:custom_uid], anything)
      ModuleThatIncludesRegisterMethods.prepare_and_save_data(@params)
    end

    it "should save basic data" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:insert_or_update).with(anything, hash_including(:name => 'Foo Inc', :custom_uid => '12345'))
      ModuleThatIncludesRegisterMethods.prepare_and_save_data(@params)
    end

    it "should convert arrays and hashes to json" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:insert_or_update).with(anything, hash_including(:foo => ['bar','baz'].to_json, :foo2 => {:bar => 'baz'}.to_json))
      ModuleThatIncludesRegisterMethods.prepare_and_save_data(@params)
    end

    it "should convert time and datetimes to iso601 version" do
      some_date = Date.parse('2012-04-23')
      some_time = Time.now
      expect(ModuleThatIncludesRegisterMethods).to receive(:insert_or_update).with(anything, hash_including(:some_date => some_date.iso8601, :some_time => some_time.iso8601))
      ModuleThatIncludesRegisterMethods.prepare_and_save_data(@params.merge(:some_date => some_date, :some_time => some_time))
    end

    it "should not change original params" do
      dup_params = Marshal.load( Marshal.dump(@params) )
      ModuleThatIncludesRegisterMethods.prepare_and_save_data(@params)
      expect(@params).to eq(dup_params)
    end

    it "should return true" do
      expect(ModuleThatIncludesRegisterMethods.prepare_and_save_data(@params)).to be_truthy
    end
  end


  describe "#update_datum for uid" do
    before do
      @dummy_time = Time.now
      @uid = '23456'
      allow(Time).to receive(:now).and_return(@dummy_time)
      @fetch_datum_response = 'some really useful data'
      # @processed_data = ModuleThatIncludesRegisterMethods.process_datum(@fetch_datum_response)
      @processed_data = {:foo => 'bar'}
      allow(ModuleThatIncludesRegisterMethods).to receive(:fetch_datum).and_return(@fetch_datum_response)
      allow(ModuleThatIncludesRegisterMethods).to receive(:process_datum).and_return(@processed_data)
      @processed_data_with_retrieved_at_and_uid = @processed_data.merge(:custom_uid => @uid, :retrieved_at => @dummy_time)
      allow(ModuleThatIncludesRegisterMethods).to receive(:save_data!)
      allow(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).and_return([])
      allow(ModuleThatIncludesRegisterMethods).to receive(:insert_or_update)
    end

    it "should fetch_datum for company number" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:fetch_datum).with(@uid).and_return(@fetch_datum_response)
      ModuleThatIncludesRegisterMethods.update_datum(@uid)
    end

    context "and nothing returned from fetch_datum" do
      before do
        allow(ModuleThatIncludesRegisterMethods).to receive(:fetch_datum) # => nil
      end

      it "should not process_datum" do
        expect(ModuleThatIncludesRegisterMethods).not_to receive(:process_datum)
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      it "should not save data" do
        expect(ModuleThatIncludesRegisterMethods).not_to receive(:save_data!)
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      it "should return nil" do
        expect(ModuleThatIncludesRegisterMethods.update_datum(@uid)).to be_nil
      end

    end

    context 'and data returned from fetch_datum' do
      it "should process_datum returned from fetching" do
        expect(ModuleThatIncludesRegisterMethods).to receive(:process_datum).with(@fetch_datum_response)
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      it "should validate processed data" do
        expect(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).with(hash_including(@processed_data_with_retrieved_at_and_uid)).and_return([])
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      it "should prepare processed data for saving including timestamp" do
        expect(ModuleThatIncludesRegisterMethods).to receive(:prepare_for_saving).with(hash_including(@processed_data_with_retrieved_at_and_uid)).and_return({})
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      it "should include data in data to be prepared for saving" do
        expect(ModuleThatIncludesRegisterMethods).to receive(:prepare_for_saving).with(hash_including(:data => @fetch_datum_response)).and_return({})
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      context 'and module responds true for save_raw_data_on_filesystem' do
        before do
          expect(ModuleThatIncludesRegisterMethods).to receive(:save_raw_data_on_filesystem).and_return(true)

        end

        it "should include data in data to be prepared for saving" do
          expect(ModuleThatIncludesRegisterMethods).to receive(:prepare_for_saving).with(hash_not_including(:data => @fetch_datum_response)).and_return({})
          ModuleThatIncludesRegisterMethods.update_datum(@uid)
        end
      end

      it "should use supplied retrieved_at in preference to default" do
        different_time = (Date.today-3).iso8601
        allow(ModuleThatIncludesRegisterMethods).to receive(:process_datum).
                                          and_return(@processed_data.merge(:retrieved_at => different_time))
        expect(ModuleThatIncludesRegisterMethods).to receive(:prepare_for_saving).
                                          with(hash_including(:retrieved_at => different_time)).and_return({})
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      it "should save prepared_data" do
        allow(ModuleThatIncludesRegisterMethods).to receive(:prepare_for_saving).and_return({:foo => 'some prepared data'})

        expect(ModuleThatIncludesRegisterMethods).to receive(:insert_or_update).with([:custom_uid], hash_including(:foo => 'some prepared data'))
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      it "should return data including uid" do
        expect(ModuleThatIncludesRegisterMethods.update_datum(@uid)).to eq(@processed_data_with_retrieved_at_and_uid)
      end

      it "should not output jsonified processed data by default" do
        expect(ModuleThatIncludesRegisterMethods).not_to receive(:puts)
        ModuleThatIncludesRegisterMethods.update_datum(@uid)
      end

      RSpec::Matchers.define :jsonified_output do |expected_output|
        match do |actual|
          parsed_actual_json = JSON.parse(actual)
          parsed_actual_json.except('retrieved_at') == expected_output.except('retrieved_at') and
          parsed_actual_json['retrieved_at'].to_time.to_s == expected_output['retrieved_at'].to_time.to_s

        end
      end

      RSpec::Matchers.define :jsonified_error_details_including do |expected_output|
        match { |actual| error_details = JSON.parse(actual)['error']; expected_output.all? { |k,v| error_details[k] == v } }
      end

      context "and exception raised" do
        before do
          allow(ModuleThatIncludesRegisterMethods).to receive(:process_datum).and_raise('something went wrong')
        end

        it "should output error message as JSON if true passes as second argument" do
          expect(ModuleThatIncludesRegisterMethods).to receive(:puts).with(jsonified_error_details_including('message' => 'something went wrong', 'klass' => 'RuntimeError'))
          ModuleThatIncludesRegisterMethods.update_datum(@uid, true)
        end

        it "should raise exception if true not passed as second argument" do
          expect { ModuleThatIncludesRegisterMethods.update_datum(@uid)}.to raise_error("something went wrong updating entry with uid: #{@uid}")
        end
      end

      context 'and passed true as to signal called_externally' do
        it 'should pass :ignore_out_of_hours_settings => true to fetch_datum' do
          allow(ModuleThatIncludesRegisterMethods).to receive(:puts)
          expect(ModuleThatIncludesRegisterMethods).to receive(:fetch_datum).with(@uid, :ignore_out_of_hours_settings => true).and_return(@fetch_datum_response)
          ModuleThatIncludesRegisterMethods.update_datum(@uid, true)
        end

        it "should output jsonified processed data to STDOUT" do
          expected_output = @processed_data_with_retrieved_at_and_uid.
            merge(:retrieved_at => @processed_data_with_retrieved_at_and_uid[:retrieved_at].iso8601).stringify_keys
          expect(ModuleThatIncludesRegisterMethods).to receive(:puts).with(jsonified_output(expected_output))
          ModuleThatIncludesRegisterMethods.update_datum(@uid, true)
        end

        context "and exception raised" do
          before do
            allow(ModuleThatIncludesRegisterMethods).to receive(:process_datum).and_raise('something went wrong')
          end

          it "should output error message as JSON" do
            expect(ModuleThatIncludesRegisterMethods).to receive(:puts).with(jsonified_error_details_including('message' => 'something went wrong', 'klass' => 'RuntimeError'))
            ModuleThatIncludesRegisterMethods.update_datum(@uid, true)
          end
        end
      end

      context 'and errors returned validating data' do
        it "should validate processed data" do
          allow(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).and_return([{:failed_attribute => 'foo', :message => 'Something not right'}])
          expect { ModuleThatIncludesRegisterMethods.update_datum(@uid)}.to raise_error(OpencBot::RecordInvalid)
        end


      end

      context 'and process_datum returns nil' do
        before do
          allow(ModuleThatIncludesRegisterMethods).to receive(:process_datum).and_return(nil)
        end

        it 'should return nil' do
          ModuleThatIncludesRegisterMethods.update_datum(@uid)
        end

        it 'should not validate_datum' do
          expect(ModuleThatIncludesRegisterMethods).not_to receive(:validate_datum)
          ModuleThatIncludesRegisterMethods.update_datum(@uid)
        end

      end
    end
  end

  describe '#registry_url for uid' do
    it 'should get computed_registry_url' do
      expect(ModuleThatIncludesRegisterMethods).to receive(:computed_registry_url).with('338811').and_return('http://some.url')
      expect(ModuleThatIncludesRegisterMethods.registry_url('338811')).to eq('http://some.url')
    end

    context "and computed_registry_url returns nil" do
      it 'should get registry_url_from_db' do
        allow(ModuleThatIncludesRegisterMethods).to receive(:computed_registry_url)
        expect(ModuleThatIncludesRegisterMethods).to receive(:registry_url_from_db).with('338811').and_return('http://another.url')
        expect(ModuleThatIncludesRegisterMethods.registry_url('338811')).to eq('http://another.url')
      end
    end

    context "and everything returns nil" do
      it 'should raise appropriate exception' do
        allow(ModuleThatIncludesRegisterMethods).to receive(:computed_registry_url)
        allow(ModuleThatIncludesRegisterMethods).to receive(:registry_url_from_db)
        expect {
          ModuleThatIncludesRegisterMethods.registry_url('338811')
        }.to raise_error(OpencBot::SingleRecordUpdateNotImplemented)
      end
    end
  end

  describe "#fetch_registry_page for uid" do
    before do
      allow(ModuleThatIncludesRegisterMethods).to receive(:registry_url).and_return('http://some.registry.url')
      allow(ModuleThatIncludesRegisterMethods).to receive(:_http_get).and_return(:registry_page_html)
    end

    it "should GET registry_page for registry_url for company_number" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:registry_url).
                                        with('76543').and_return('http://some.registry.url')
      expect(ModuleThatIncludesRegisterMethods).to receive(:_http_get).with('http://some.registry.url',{})
      ModuleThatIncludesRegisterMethods.fetch_registry_page('76543')
    end

    it "should return result of GETing registry_page" do
      allow(ModuleThatIncludesRegisterMethods).to receive(:_http_get).and_return(:registry_page_html)
      expect(ModuleThatIncludesRegisterMethods.fetch_registry_page('76543')).to eq(:registry_page_html)
    end

    it "should pass on options" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:registry_url).
                                        with('76543').and_return('http://some.registry.url')
      expect(ModuleThatIncludesRegisterMethods).to receive(:_http_get).with('http://some.registry.url', :foo => 'bar')
      ModuleThatIncludesRegisterMethods.fetch_registry_page('76543', :foo => 'bar')
    end

    context 'and SLEEP_BEFORE_HTTP_REQ is set' do
      it 'should sleep for given period' do
        expect(ModuleThatIncludesRegisterMethods).to receive(:sleep).with(2)
        ModuleThatIncludesRegisterMethods.fetch_registry_page('76543')
      end
    end

    context 'and SLEEP_BEFORE_HTTP_REQ is not set' do
      before do
        allow(ModuleWithNoCustomPrimaryKey).to receive(:_http_get)
        allow(ModuleWithNoCustomPrimaryKey).to receive(:registry_url).and_return('http://some.registry.url')

      end

      it 'should sleep for given period' do
        expect(ModuleWithNoCustomPrimaryKey).not_to receive(:sleep)
        ModuleWithNoCustomPrimaryKey.fetch_registry_page('76543')
      end
    end
  end

  describe "#validate_datum" do
    before do
      @valid_params = {:name => 'Foo Inc', :company_number => '12345', :jurisdiction_code => 'ie'}
    end

    it "should check json version of datum against given schema" do
      expect(JSON::Validator).to receive(:fully_validate).with('company-schema.json', @valid_params.to_json, anything)
      ModuleThatIncludesRegisterMethods.validate_datum(@valid_params)
    end

    context "and datum is valid" do
      it "should return empty array" do
        expect(ModuleThatIncludesRegisterMethods.validate_datum(@valid_params)).to eq([])
      end
    end

    context "and datum is not valid" do
      it "should return errors" do
        result = ModuleThatIncludesRegisterMethods.validate_datum({:name => 'Foo Inc', :jurisdiction_code => 'ie'})
        expect(result).to be_kind_of Array
        expect(result.size).to eq(1)
        expect(result.first[:failed_attribute]).to eq("Required")
        expect(result.first[:message]).to match 'company_number'
      end
    end
  end

  describe "save_entity" do
    before do
      @params = {:name => 'Foo Inc', :custom_uid => '12345', :data => {:foo => 'bar'}}
    end

    it "should validate entity data" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).with(@params.except(:data)).and_return([])
      ModuleThatIncludesRegisterMethods.save_entity(@params)
    end

    context "and entity_data is valid (excluding :data)" do
      before do
        allow(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).and_return([])
      end

      it "should prepare and save data" do
        expect(ModuleThatIncludesRegisterMethods).to receive(:prepare_and_save_data).with(@params)
        ModuleThatIncludesRegisterMethods.save_entity(@params)
      end

      it "should return true" do
        expect(ModuleThatIncludesRegisterMethods.save_entity(@params)).to be_truthy
      end
    end

    context "and entity_data is not valid" do
      before do
        allow(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).and_return([{:message=>'Not valid'}])
      end

      it "should not prepare and save data" do
        expect(ModuleThatIncludesRegisterMethods).not_to receive(:prepare_and_save_data)
        ModuleThatIncludesRegisterMethods.save_entity(@params)
      end

      it "should not return true" do
        expect(ModuleThatIncludesRegisterMethods.save_entity(@params)).not_to be true
      end
    end
  end

  describe "save_entity!" do
    before do
      @params = {:name => 'Foo Inc', :custom_uid => '12345', :data => {:foo => 'bar'}}
    end

    it "should validate entity data (excluding :data)" do
      expect(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).with(@params.except(:data)).and_return([])
      ModuleThatIncludesRegisterMethods.save_entity!(@params)
    end

    context "and entity_data is valid" do
      before do
        allow(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).and_return([])
      end

      it "should prepare and save data" do
        expect(ModuleThatIncludesRegisterMethods).to receive(:prepare_and_save_data).with(@params)
        ModuleThatIncludesRegisterMethods.save_entity!(@params)
      end

      it "should return true" do
        expect(ModuleThatIncludesRegisterMethods.save_entity!(@params)).to be_truthy
      end
    end

    context "and entity_data is not valid" do
      before do
        allow(ModuleThatIncludesRegisterMethods).to receive(:validate_datum).and_return([{:message=>'Not valid'}])
      end

      it "should not prepare and save data" do
        expect(ModuleThatIncludesRegisterMethods).not_to receive(:prepare_and_save_data)
        lambda {ModuleThatIncludesRegisterMethods.save_entity!(@params)}
      end

      it "should raise exception" do
        expect {ModuleThatIncludesRegisterMethods.save_entity!(@params)}.to raise_error(OpencBot::RecordInvalid)
      end
    end
  end

  describe '#post_process' do
    before do
      @unprocessed_data = { :name => 'Foo Corp',
        :company_number => '12345',
        :serialised_field_1 => "[\"foo\",\"bar\"]",
        :serialised_field_2 => "[{\"position\":\"gestor\",\"name\":\"JOSE MANUEL REYES R.\",\"other_attributes\":{\"foo\":\"bar\"}}]",
        :serialised_field_3 => "{\"foo\":\"bar\"}",
        :serialised_field_4 => "[]",
        :serialised_field_5 => "{}",
        :serialised_field_6 => nil,
      }
    end

    context 'in general' do
      before do
        @processed_data = ModuleThatIncludesRegisterMethods.post_process(@unprocessed_data)
      end

      it 'should include non-serialised fields' do
        expect(@processed_data[:name]).to eq(@unprocessed_data[:name])
        expect(@processed_data[:company_number]).to eq(@unprocessed_data[:company_number])
      end

      it 'should deserialize fields' do
        expect(@processed_data[:serialised_field_1]).to eq(['foo','bar'])
        expect(@processed_data[:serialised_field_3]).to eq({'foo' => 'bar'})
        expect(@processed_data[:serialised_field_4]).to eq([])
        expect(@processed_data[:serialised_field_5]).to eq({})
      end

      it 'should deserialize nested fields correctly' do
        expect(@processed_data[:serialised_field_2].first[:position]).to eq("gestor")
        expect(@processed_data[:serialised_field_2].first[:other_attributes][:foo]).to eq("bar")
      end

      it 'should not do anything with null value' do
        expect(@processed_data[:serialised_field_6]).to be_nil
        expect(@processed_data.has_key?(:serialised_field_6)).to be true
      end
    end

    context 'with `skip_nulls` argument as true' do
      before do
        @processed_data = ModuleThatIncludesRegisterMethods.post_process(@unprocessed_data, true)
      end

      it 'should remove value from result' do
        expect(@processed_data.has_key?(:serialised_field_6)).to be false
      end
    end


    context "and there is generic :data field" do
      it "should not include it" do
        expect(ModuleThatIncludesRegisterMethods.post_process(@unprocessed_data.merge(:data => 'something else'))[:data]).to be_nil
        expect(ModuleThatIncludesRegisterMethods.post_process(@unprocessed_data.merge(:data => "{\"bar\":\"baz\"}"))[:data]).to be_nil
      end
    end
  end

  describe 'allowed_hours' do
    it "should return ALLOWED_HOURS if ALLOWED_HOURS defined" do
      stub_const("ModuleThatIncludesRegisterMethods::ALLOWED_HOURS", (2..5))
      expect(ModuleThatIncludesRegisterMethods.allowed_hours).to eq([2,3,4,5])
    end

    it "should return nil if ALLOWED_HOURS not defined" do
      expect(ModuleThatIncludesRegisterMethods.allowed_hours).to be_nil
    end

    context 'and TIMEZONE defined' do
      it "should return default non-working hours" do
        stub_const("ModuleThatIncludesRegisterMethods::TIMEZONE", 'America/Panama')
        expect(ModuleThatIncludesRegisterMethods.allowed_hours).to eq([18, 19, 20, 21, 22, 23, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8])
        stub_const("ModuleThatIncludesRegisterMethods::TIMEZONE", "Australia/Adelaide")
        expect(ModuleThatIncludesRegisterMethods.allowed_hours).to eq([18, 19, 20, 21, 22, 23, 24, 0, 1, 2, 3, 4, 5, 6, 7, 8])
      end
    end
  end

  describe 'current_time_in_zone' do
    before do
      @dummy_time = Time.now
      allow(Time).to receive(:now).and_return(@dummy_time)
    end

    after do
      allow(Time).to receive(:now).and_call_original
    end

    it 'should return time now' do
      expect(ModuleThatIncludesRegisterMethods.current_time_in_zone).to eq(@dummy_time)
    end

    context 'and TIMEZONE defined' do
      it "should return time in timezone" do
        stub_const("ModuleThatIncludesRegisterMethods::TIMEZONE", 'America/Panama')
        expect(ModuleThatIncludesRegisterMethods.current_time_in_zone).to eq(TZInfo::Timezone.get('America/Panama').now)
        stub_const("ModuleThatIncludesRegisterMethods::TIMEZONE", "Australia/Adelaide")
        expect(ModuleThatIncludesRegisterMethods.current_time_in_zone).to eq(TZInfo::Timezone.get("Australia/Adelaide").now)
      end
    end
  end

  describe 'in_prohibited_time?' do
    before do
      allow(ModuleThatIncludesRegisterMethods).to receive(:allowed_hours).and_return((0..12))
    end

    it 'should return true only if current_time_in_zone out of office hours' do
      times_and_truthiness = {
        "2014-10-09 04:14:25 +0100" => false, # weekday out of hours
        "2014-10-11 15:14:25 +0100" => false, # in weekend
        "2014-10-10 15:14:25 +0100" => true # weekday in business hours
      }
      times_and_truthiness.each do |datetime, truthiness|
        allow(ModuleThatIncludesRegisterMethods).to receive(:current_time_in_zone).and_return(Time.parse(datetime))
        expect(ModuleThatIncludesRegisterMethods.in_prohibited_time?).to eq(truthiness), "Wrong result for #{datetime} and in_prohibited_time (was #{!truthiness}, expected #{truthiness}) "
      end
    end

    it 'should return false if allowed_hours not defined' do
      expect(ModuleWithNoCustomPrimaryKey.in_prohibited_time?).to be_nil
    end
  end

  describe 'raise_when_saving_invalid_record' do
    it 'should return false if RAISE_WHEN_SAVING_INVALID_RECORD not set' do
      expect(ModuleWithNoCustomPrimaryKey.send(:raise_when_saving_invalid_record)).to eq(false)
    end

    it 'should return true if RAISE_WHEN_SAVING_INVALID_RECORD set' do
      expect(ModuleThatIncludesRegisterMethods.send(:raise_when_saving_invalid_record)).to eq(true)
    end
  end

  describe '#save_raw_data_on_filesystem' do
    it 'should return false if SAVE_RAW_DATA_ON_FILESYSTEM not set' do
      expect(ModuleThatIncludesRegisterMethods.send(:save_raw_data_on_filesystem)).to eq(false)
    end

    it 'should return true if SAVE_RAW_DATA_ON_FILESYSTEM set' do
      expect(ModuleWithNoCustomPrimaryKey.send(:save_raw_data_on_filesystem)).to eq(true)
    end
  end

  describe '#raw_data_file_location for a uid' do
    before do
      @dummy_root_directory = File.join(File.dirname(__FILE__),'..','..','tmp')
      Dir.mkdir(@dummy_root_directory) unless Dir.exist?(@dummy_root_directory)

      allow(ModuleThatIncludesRegisterMethods).to receive(:root_directory).and_return(@dummy_root_directory)
    end

    after do
      FileUtils.rmdir(File.join(@dummy_root_directory, 'data'))
    end

    it 'should return directory built from uid inside root data directory' do
      expect(ModuleThatIncludesRegisterMethods.raw_data_file_location('123456', 'html')).to eq(File.join(@dummy_root_directory, 'data', '1','2','3','4','5', '123456.html'))
    end

    it 'should create directory structure if it doesnt exist' do
      ModuleThatIncludesRegisterMethods.raw_data_file_location('123456', 'html')
      expect(Dir.exist?(File.join(@dummy_root_directory, 'data', '1','2','3','4','5'))).to eq(true)
    end

    it 'should ignore leading zeroes when building directory' do
      expect(ModuleThatIncludesRegisterMethods.raw_data_file_location('001234', 'html')).to eq(File.join(@dummy_root_directory, 'data', '1','2','3','4', '001234.html'))
    end

    it 'should cope with number as uid' do
      expect(ModuleThatIncludesRegisterMethods.raw_data_file_location(1234, 'html')).to eq(File.join(@dummy_root_directory, 'data', '1','2','3','4', '1234.html'))
    end

    it 'should ignore non alphanum chars when building directory' do
      expect(ModuleThatIncludesRegisterMethods.raw_data_file_location('12a-b/3456', 'html')).to eq(File.join(@dummy_root_directory, 'data', '1','2','a','b','3', '12ab3456.html'))
    end

    it 'should allow format to be missing' do
      expect(ModuleThatIncludesRegisterMethods.raw_data_file_location('12a-b/3456')).to eq(File.join(@dummy_root_directory, 'data', '1','2','a','b','3', '12ab3456'))
    end

    it 'should allow format to be nil' do
      expect(ModuleThatIncludesRegisterMethods.raw_data_file_location('12a-b/3456', nil)).to eq(File.join(@dummy_root_directory, 'data', '1','2','a','b','3', '12ab3456'))
    end
  end

  describe '#save_raw_data' do
    before do
      @dummy_root_directory = File.join(File.dirname(__FILE__),'..','..','tmp')
      Dir.mkdir(@dummy_root_directory) unless Dir.exist?(@dummy_root_directory)

      allow(ModuleThatIncludesRegisterMethods).to receive(:root_directory).and_return(@dummy_root_directory)
    end

    it 'should save raw data as in computed raw_data_file_location' do
      ModuleThatIncludesRegisterMethods.save_raw_data('foo bar', '12a-b/3456', 'html')
      expect(File.read(File.join(@dummy_root_directory, 'data', '1','2','a','b','3', '12ab3456.html'))).to eq('foo bar')
    end

    it 'should allow format to be missing' do
      ModuleThatIncludesRegisterMethods.save_raw_data('foo bar', '12a-b/3456')
      expect(File.read(File.join(@dummy_root_directory, 'data', '1','2','a','b','3', '12ab3456'))).to eq('foo bar')
    end
  end

  describe '#get_raw_data' do
    before do
      @dummy_root_directory = File.join(File.dirname(__FILE__),'..','..','tmp')
      Dir.mkdir(@dummy_root_directory) unless Dir.exist?(@dummy_root_directory)

      allow(ModuleThatIncludesRegisterMethods).to receive(:root_directory).and_return(@dummy_root_directory)
    end

    it 'should read raw data in computed raw_data_file_location' do
      File.open(File.join(@dummy_root_directory, 'data', '1','2','a','b','3', '12ab3456.html'),'w') { |f| f.print 'foo bar' }
      expect(ModuleThatIncludesRegisterMethods.get_raw_data('12a-b/3456', 'html')).to eq('foo bar')
    end

    it 'should allow format to be missing' do
      File.open(File.join(@dummy_root_directory, 'data', '1','2','a','b','3', '12ab3456'),'w') { |f| f.print 'foo bar' }
      expect(ModuleThatIncludesRegisterMethods.get_raw_data('12a-b/3456')).to eq('foo bar')
    end
  end
end
