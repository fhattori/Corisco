/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.sword2;

import org.dspace.authorize.AuthorizeException;
import org.dspace.content.Collection;
import org.dspace.content.DCDate;
import org.dspace.content.DCValue;
import org.dspace.content.DSpaceObject;
import org.dspace.content.Item;
import org.dspace.content.WorkspaceItem;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.Context;
import org.swordapp.server.Deposit;
import org.swordapp.server.SwordAuthException;
import org.swordapp.server.SwordEntry;
import org.swordapp.server.SwordError;
import org.swordapp.server.SwordServerException;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

public class SimpleDCEntryIngester implements SwordEntryIngester
{
    private Map<String, String> dcMap;

	public SimpleDCEntryIngester()
    {
        // we should load our DC map from configuration
        this.dcMap = new HashMap<String, String>();
        Properties props = ConfigurationManager.getProperties("swordv2-server");
        for (Object key : props.keySet())
        {
            String keyString = (String) key;
            if (keyString.startsWith("simpledc."))
            {
                String k = keyString.substring("simpledc.".length());
                String v = (String) props.get(key);
                this.dcMap.put(k, v);
            }
        }
    }

	public DepositResult ingest(Context context, Deposit deposit, DSpaceObject dso, VerboseDescription verboseDescription)
            throws DSpaceSwordException, SwordError, SwordAuthException, SwordServerException
    {
        return this.ingest(context, deposit, dso, verboseDescription, null, false);
    }

	public DepositResult ingest(Context context, Deposit deposit, DSpaceObject dso, VerboseDescription verboseDescription, DepositResult result, boolean replace)
            throws DSpaceSwordException, SwordError, SwordAuthException, SwordServerException
    {
		if (dso instanceof Collection)
        {
            return this.ingestToCollection(context, deposit, (Collection) dso, verboseDescription, result);
        }
		else if (dso instanceof Item)
        {
            return this.ingestToItem(context, deposit, (Item) dso, verboseDescription, result, replace);
        }
		return null;
	}

	public DepositResult ingestToItem(Context context, Deposit deposit, Item item, VerboseDescription verboseDescription, DepositResult result, boolean replace)
            throws DSpaceSwordException, SwordError, SwordAuthException, SwordServerException
    {
		try
		{
			if (result == null)
			{
				result = new DepositResult();
			}
			result.setItem(item);

			// NOTE: this implementation does not remove pre-existing metadata, as that is actually
			// rather hard to handle in DSpace (what do you do about provenance and other administrator
			// added metadata?).  Instead "replace" does nothing different to "create new" or "add".

			// add the metadata to the item
			this.addMetadataToItem(deposit, item);

			// update the item metadata to inclue the current time as
			// the updated date
			this.setUpdatedDate(item, verboseDescription);

			// in order to write these changes, we need to bypass the
			// authorisation briefly, because although the user may be
			// able to add stuff to the repository, they may not have
			// WRITE permissions on the archive.
			boolean ignore = context.ignoreAuthorization();
			context.setIgnoreAuthorization(true);
			item.update();
			context.setIgnoreAuthorization(ignore);

			verboseDescription.append("Update successful");

			result.setItem(item);
			result.setTreatment(this.getTreatment());

			return result;
		}
		catch (SQLException e)
		{
			throw new DSpaceSwordException(e);
		}
		catch (AuthorizeException e)
		{
			throw new DSpaceSwordException(e);
		}
	}

	private void addMetadataToItem(Deposit deposit, Item item)
			throws DSpaceSwordException
	{
		// now, go through and get the metadata from the EntryPart and put it in DSpace
		SwordEntry se = deposit.getSwordEntry();

		// first do the standard atom terms (which may get overridden later)
		String title = se.getTitle();
		String summary = se.getSummary();
		if (title != null)
		{
			String titleField = this.dcMap.get("title");
			if (titleField != null)
			{
				DCValue dcv = this.makeDCValue(titleField, title);
				item.addMetadata(dcv.schema, dcv.element, dcv.qualifier, dcv.language, dcv.value);
			}
		}
		if (summary != null)
		{
			String abstractField = this.dcMap.get("abstract");
			if (abstractField != null)
			{
				DCValue dcv = this.makeDCValue(abstractField, summary);
				item.addMetadata(dcv.schema, dcv.element, dcv.qualifier, dcv.language, dcv.value);
			}
		}

		Map<String, List<String>> dc = se.getDublinCore();
		for (String term : dc.keySet())
		{
			String dsTerm = this.dcMap.get(term);
			if (dsTerm == null)
			{
				// ignore anything we don't understand
				continue;
			}

			// clear any pre-existing metadata
			DCValue dcv = this.makeDCValue(dsTerm, null);
			if (dcv.qualifier == null)
			{
				item.clearMetadata(dcv.schema, dcv.element, Item.ANY, Item.ANY);
			}
			else
			{
				item.clearMetadata(dcv.schema, dcv.element, dcv.qualifier, Item.ANY);
			}

			// now add all the metadata terms
			for (String value : dc.get(term))
			{
				item.addMetadata(dcv.schema, dcv.element, dcv.qualifier, dcv.language, value);
			}
		}
	}

	public DepositResult ingestToCollection(Context context, Deposit deposit, Collection collection, VerboseDescription verboseDescription, DepositResult result)
            throws DSpaceSwordException, SwordError, SwordAuthException, SwordServerException
    {
        try
		{
			// decide whether we have a new item or an existing one
            Item item = null;
            WorkspaceItem wsi = null;
            if (result != null)
            {
                item = result.getItem();
            }
            else
            {
                result = new DepositResult();
            }
            if (item == null)
            {
                // simple zip ingester uses the item template, since there is no native metadata
                wsi = WorkspaceItem.create(context, collection, true);
                item = wsi.getItem();
            }

            // add the metadata to the item
			this.addMetadataToItem(deposit, item);

			// update the item metadata to inclue the current time as
			// the updated date
			this.setUpdatedDate(item, verboseDescription);

			// DSpace ignores the slug value as suggested identifier, but
			// it does store it in the metadata
			this.setSlug(item, deposit.getSlug(), verboseDescription);

			// in order to write these changes, we need to bypass the
			// authorisation briefly, because although the user may be
			// able to add stuff to the repository, they may not have
			// WRITE permissions on the archive.
			boolean ignore = context.ignoreAuthorization();
			context.setIgnoreAuthorization(true);
			item.update();
			context.setIgnoreAuthorization(ignore);

			verboseDescription.append("Ingest successful");
			verboseDescription.append("Item created with internal identifier: " + item.getID());

			result.setItem(item);
			result.setTreatment(this.getTreatment());

			return result;
		}
		catch (AuthorizeException e)
		{
			throw new SwordAuthException(e);
		}
		catch (SQLException e)
		{
			throw new DSpaceSwordException(e);
		}
		catch (IOException e)
		{
			throw new DSpaceSwordException(e);
		}
    }

	


    public DCValue makeDCValue(String field, String value)
            throws DSpaceSwordException
    {
        DCValue dcv = new DCValue();
        String[] bits = field.split("\\.");
        if (bits.length < 2 || bits.length > 3)
        {
            throw new DSpaceSwordException("invalid DC value: " + field);
        }
        dcv.schema = bits[0];
        dcv.element = bits[1];
        if (bits.length == 3)
        {
            dcv.qualifier = bits[2];
        }
        dcv.value = value;
        return dcv;
    }

    /**
	 * Add the current date to the item metadata.  This looks up
	 * the field in which to store this metadata in the configuration
	 * sword.updated.field
	 *
	 * @param item
	 * @throws DSpaceSwordException
	 */
	protected void setUpdatedDate(Item item, VerboseDescription verboseDescription)
			throws DSpaceSwordException
	{
		String field = ConfigurationManager.getProperty("swordv2-server", "updated.field");
		if (field == null || "".equals(field))
		{
			throw new DSpaceSwordException("No configuration, or configuration is invalid for: sword.updated.field");
		}

		DCValue dc = this.makeDCValue(field, null);
		item.clearMetadata(dc.schema, dc.element, dc.qualifier, Item.ANY);
		DCDate date = new DCDate(new Date());
		item.addMetadata(dc.schema, dc.element, dc.qualifier, null, date.toString());

		verboseDescription.append("Updated date added to response from item metadata where available");
	}

	/**
	 * Store the given slug value (which is used for suggested identifiers,
	 * and which DSpace ignores) in the item metadata.  This looks up the
	 * field in which to store this metadata in the configuration
	 * sword.slug.field
	 *
	 * @param item
	 * @param slugVal
	 * @throws DSpaceSwordException
	 */
	protected void setSlug(Item item, String slugVal, VerboseDescription verboseDescription)
			throws DSpaceSwordException
	{
		// if there isn't a slug value, don't set it
		if (slugVal == null)
		{
			return;
		}

		String field = ConfigurationManager.getProperty("swordv2-server", "slug.field");
		if (field == null || "".equals(field))
		{
			throw new DSpaceSwordException("No configuration, or configuration is invalid for: sword.slug.field");
		}

		DCValue dc = this.makeDCValue(field, null);
		item.clearMetadata(dc.schema, dc.element, dc.qualifier, Item.ANY);
		item.addMetadata(dc.schema, dc.element, dc.qualifier, null, slugVal);

		verboseDescription.append("Slug value set in response where available");
	}

    /**
	 * The human readable description of the treatment this ingester has
	 * put the deposit through
	 *
	 * @return
	 * @throws DSpaceSwordException
	 */
	private String getTreatment() throws DSpaceSwordException
	{
		return "A metadata only item has been created";
	}
}
